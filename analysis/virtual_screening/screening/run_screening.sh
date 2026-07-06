#!/usr/bin/env bash
# =============================================================================
# CRIBADO VIRTUAL MASIVO CON AUTODOCK VINA  (v2 — bug fix en extraer_scores)
# Automatización completa para dos receptores: Humana y Hongo
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# SECCIÓN 1: CONFIGURACIÓN GLOBAL DE RUTAS Y PARÁMETROS
# -----------------------------------------------------------------------------

PROYECTO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RECEPTOR_HUMANA="${PROYECTO_DIR}/receptores/complex-7RSP.pdbqt"
RECEPTOR_HONGO="${PROYECTO_DIR}/receptores/model05_sup_complex_h.pdbqt"

CONFIG_HUMANA="${PROYECTO_DIR}/configs/vina_config_humana.txt"
CONFIG_HONGO="${PROYECTO_DIR}/configs/vina_config_honguito.txt"

DB_LIGANDOS="/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/DB_1000m"

RESULTADOS_HUMANA="${PROYECTO_DIR}/resultados_humana"
RESULTADOS_HONGO="${PROYECTO_DIR}/resultados_hongo"

LOG_ERRORES="${PROYECTO_DIR}/errores.log"

CPU_CORES=15
NUM_MODES=1
EXHAUSTIVENESS=8
VINA_BIN="vina"

# =============================================================================
# SECCIÓN 2: FUNCIONES AUXILIARES
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# CORRECCIÓN: Todos los mensajes de log van a stderr (>&2)
# Esto deja stdout limpio para que las funciones puedan "retornar" valores
# capturables con $(...) sin que los mensajes contaminen la variable.
log_info()   { echo -e "${CYAN}[INFO]${NC}  $(date '+%H:%M:%S') $*" >&2; }
log_ok()     { echo -e "${GREEN}[OK]${NC}    $(date '+%H:%M:%S') $*" >&2; }
log_warn()   { echo -e "${YELLOW}[WARN]${NC}  $(date '+%H:%M:%S') $*" >&2; }
log_error()  { echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') $*" >&2; }
log_header() { echo -e "\n${BOLD}${CYAN}========== $* ==========${NC}\n" >&2; }

registrar_error() {
    local receptor="$1"
    local ligando="$2"
    local mensaje="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # El archivo de errores recibe siempre texto plano (sin colores)
    echo "[${timestamp}] RECEPTOR=${receptor} | LIGANDO=$(basename "${ligando}") | ERROR: ${mensaje}" >> "${LOG_ERRORES}"
    log_error "Ligando fallido: $(basename "${ligando}") → ${mensaje}"
}

verificar_archivo() {
    local archivo="$1"
    local descripcion="$2"
    if [[ ! -f "${archivo}" ]]; then
        log_error "No se encuentra ${descripcion}: ${archivo}"
        exit 1
    fi
    if [[ ! -s "${archivo}" ]]; then
        log_error "${descripcion} está vacío: ${archivo}"
        exit 1
    fi
    log_ok "${descripcion} verificado: ${archivo}"
}

contar_ligandos() {
    find "${DB_LIGANDOS}" -maxdepth 1 -name "*.pdbqt" | wc -l
}

# =============================================================================
# SECCIÓN 3: VERIFICACIONES PREVIAS AL CRIBADO
# =============================================================================

verificar_dependencias() {
    log_header "VERIFICANDO DEPENDENCIAS"

    if ! command -v "${VINA_BIN}" &>/dev/null; then
        log_error "AutoDock Vina no encontrado. Instálalo o ajusta VINA_BIN en el script."
        log_info  "  → Ubuntu/Debian: sudo apt install autodock-vina"
        exit 1
    fi
    log_ok "Vina encontrado: $(command -v ${VINA_BIN})"

    if ! command -v python3 &>/dev/null; then
        log_warn "Python3 no encontrado. Los histogramas no podrán generarse automáticamente."
    else
        log_ok "Python3 disponible: $(python3 --version)"
    fi

    if [[ ! -d "${DB_LIGANDOS}" ]]; then
        log_error "Directorio de ligandos no encontrado: ${DB_LIGANDOS}"
        exit 1
    fi

    local n_ligandos
    n_ligandos=$(contar_ligandos)
    if [[ "${n_ligandos}" -eq 0 ]]; then
        log_error "No se encontraron archivos .pdbqt en: ${DB_LIGANDOS}"
        exit 1
    fi
    log_ok "Base de datos de ligandos: ${n_ligandos} archivos .pdbqt encontrados"

    verificar_archivo "${RECEPTOR_HUMANA}"  "Receptor Humana"
    verificar_archivo "${RECEPTOR_HONGO}"   "Receptor Hongo"
    verificar_archivo "${CONFIG_HUMANA}"    "Config Humana"
    verificar_archivo "${CONFIG_HONGO}"     "Config Hongo"
}

# =============================================================================
# SECCIÓN 4: PREPARACIÓN DE CARPETAS DE SALIDA
# =============================================================================

crear_estructura_directorios() {
    log_header "CREANDO ESTRUCTURA DE DIRECTORIOS"

    mkdir -p "${RESULTADOS_HUMANA}"
    mkdir -p "${RESULTADOS_HONGO}"

    log_ok "Carpeta creada/verificada: ${RESULTADOS_HUMANA}"
    log_ok "Carpeta creada/verificada: ${RESULTADOS_HONGO}"

    : > "${LOG_ERRORES}"
    log_ok "Archivo de errores inicializado: ${LOG_ERRORES}"
}

# =============================================================================
# SECCIÓN 5: FUNCIÓN PRINCIPAL DE DOCKING
# =============================================================================

run_docking_single() {
    local ligando_path="$1"
    local receptor_nombre="$2"
    local config_file="$3"
    local output_dir="$4"

    local ligando_basename
    ligando_basename=$(basename "${ligando_path}" .pdbqt)

    local out_pdbqt="${output_dir}/${ligando_basename}_out.pdbqt"
    local out_log="${output_dir}/${ligando_basename}.log"

    # Validar existencia
    if [[ ! -f "${ligando_path}" ]]; then
        registrar_error "${receptor_nombre}" "${ligando_path}" "Archivo no encontrado"
        return 1
    fi

    # Validar que no está vacío
    if [[ ! -s "${ligando_path}" ]]; then
        registrar_error "${receptor_nombre}" "${ligando_path}" "Archivo vacío (0 bytes)"
        return 1
    fi

    # Validar que tiene átomos válidos
    if ! grep -qE "^(ROOT|ATOM|HETATM)" "${ligando_path}" 2>/dev/null; then
        registrar_error "${receptor_nombre}" "${ligando_path}" "Archivo PDBQT sin átomos válidos (posiblemente corrupto)"
        return 1
    fi

    # Construir el comando de Vina con parámetros dinámicos
    local cmd="${VINA_BIN} \
        --config    \"${config_file}\" \
        --ligand    \"${ligando_path}\" \
        --out       \"${out_pdbqt}\" \
        --log       \"${out_log}\" \
        --cpu       ${CPU_CORES} \
        --num_modes ${NUM_MODES}"

    # Ejecutar con timeout de 5 minutos por ligando
    if timeout 300 bash -c "${cmd}" >> "${out_log}" 2>&1; then
        if [[ -s "${out_pdbqt}" ]]; then
            return 0
        else
            registrar_error "${receptor_nombre}" "${ligando_path}" "Vina finalizó pero el archivo de salida está vacío"
            return 1
        fi
    else
        local exit_code=$?
        if [[ ${exit_code} -eq 124 ]]; then
            registrar_error "${receptor_nombre}" "${ligando_path}" "Timeout excedido (>300s)"
        else
            local err_msg="Código de salida ${exit_code}"
            if [[ -f "${out_log}" ]]; then
                local last_line
                last_line=$(tail -n 1 "${out_log}" 2>/dev/null || echo "sin detalles")
                err_msg="${err_msg} | ${last_line}"
            fi
            registrar_error "${receptor_nombre}" "${ligando_path}" "${err_msg}"
        fi
        return 1
    fi
}

# =============================================================================
# SECCIÓN 6: LOOP PRINCIPAL DE CRIBADO
# =============================================================================

ejecutar_cribado() {
    local receptor_nombre="$1"
    local config_file="$2"
    local output_dir="$3"

    log_header "INICIANDO CRIBADO: ${receptor_nombre^^}"

    local total
    total=$(contar_ligandos)
    local contador=0
    local exitosos=0
    local fallidos=0
    local tiempo_inicio
    tiempo_inicio=$(date +%s)

    log_info "Total de ligandos a procesar: ${total}"
    log_info "Resultados → ${output_dir}"
    echo "" >&2

    while IFS= read -r -d '' ligando_path; do
        ((contador++)) || true

        local ligando_nombre
        ligando_nombre=$(basename "${ligando_path}" .pdbqt)

        local porcentaje=$(( (contador * 100) / total ))

        # La barra de progreso también va a stderr para no contaminar stdout
        printf "\r${CYAN}[%s]${NC} Progreso: %d/%d (%d%%) | OK: %d | Fail: %d | %s    " \
            "${receptor_nombre}" "${contador}" "${total}" "${porcentaje}" \
            "${exitosos}" "${fallidos}" "${ligando_nombre:0:30}" >&2

        if run_docking_single \
                "${ligando_path}" \
                "${receptor_nombre}" \
                "${config_file}" \
                "${output_dir}"; then
            ((exitosos++)) || true
        else
            ((fallidos++)) || true
        fi

    done < <(find "${DB_LIGANDOS}" -maxdepth 1 -name "*.pdbqt" -print0 | sort -z)

    echo "" >&2

    local tiempo_fin
    tiempo_fin=$(date +%s)
    local duracion=$(( tiempo_fin - tiempo_inicio ))
    local horas=$(( duracion / 3600 ))
    local minutos=$(( (duracion % 3600) / 60 ))
    local segundos=$(( duracion % 60 ))

    log_header "RESUMEN: ${receptor_nombre^^}"
    log_ok  "  Ligandos procesados  : ${total}"
    log_ok  "  Simulaciones OK      : ${exitosos}"
    log_warn "  Simulaciones fallidas: ${fallidos}"
    log_info "  Tiempo total         : ${horas}h ${minutos}m ${segundos}s"
    [[ ${fallidos} -gt 0 ]] && log_warn "  Ver errores en: ${LOG_ERRORES}"
}

# =============================================================================
# SECCIÓN 7: EXTRACCIÓN DE SCORES DESDE ARCHIVOS .PDBQT
# =============================================================================
# CORRECCIÓN CLAVE: Esta función ahora imprime a stderr todo excepto
# la ruta del CSV al final, que va a stdout para ser capturada con $()

extraer_scores() {
    local output_dir="$1"
    local receptor_nombre="$2"
    local scores_csv="${output_dir}/scores_${receptor_nombre}.csv"

    log_header "EXTRAYENDO SCORES: ${receptor_nombre^^}"

    echo "ligando,score_kcal_mol" > "${scores_csv}"

    local n_extraidos=0
    local n_sin_score=0

    while IFS= read -r -d '' pdbqt_out; do
        local nombre_ligando
        nombre_ligando=$(basename "${pdbqt_out}" _out.pdbqt)

        # Formato estándar en el PDBQT: "REMARK VINA RESULT:    -8.5 ..."
        local score
        score=$(grep -m 1 "^REMARK VINA RESULT:" "${pdbqt_out}" 2>/dev/null | \
                awk '{print $4}')

        if [[ -n "${score}" ]]; then
            echo "${nombre_ligando},${score}" >> "${scores_csv}"
            ((n_extraidos++)) || true
        else
            # Fallback: leer del archivo .log (versiones GPU/QuickVina)
            local log_file="${output_dir}/${nombre_ligando}.log"
            if [[ -f "${log_file}" ]]; then
                score=$(grep -m 1 "^   1 " "${log_file}" 2>/dev/null | \
                        awk '{print $2}')
                if [[ -n "${score}" ]]; then
                    echo "${nombre_ligando},${score}" >> "${scores_csv}"
                    ((n_extraidos++)) || true
                else
                    echo "${nombre_ligando},NA" >> "${scores_csv}"
                    ((n_sin_score++)) || true
                fi
            else
                echo "${nombre_ligando},NA" >> "${scores_csv}"
                ((n_sin_score++)) || true
            fi
        fi
    done < <(find "${output_dir}" -maxdepth 1 -name "*_out.pdbqt" -print0 | sort -z)

    # Mensajes de log → stderr (no contaminan el valor de retorno)
    log_ok  "  Scores extraídos  : ${n_extraidos}" 
    [[ ${n_sin_score} -gt 0 ]] && log_warn "  Sin score (NA)    : ${n_sin_score}"
    log_ok  "  CSV generado      : ${scores_csv}"

    # ÚNICA línea en stdout: la ruta del CSV para ser capturada por $()
    echo "${scores_csv}"
}

# =============================================================================
# SECCIÓN 8: GENERACIÓN DE HISTOGRAMAS
# =============================================================================

generar_histogramas() {
    local csv_humana="$1"
    local csv_hongo="$2"
    local script_python="${PROYECTO_DIR}/plot_histogramas.py"

    log_header "GENERANDO HISTOGRAMAS"

    if ! command -v python3 &>/dev/null; then
        log_warn "Python3 no disponible."
        return
    fi

    if [[ ! -f "${script_python}" ]]; then
        log_warn "Script Python no encontrado en ${script_python}"
        return
    fi

    # Verificar que los CSV existen y tienen contenido antes de llamar a Python
    if [[ ! -s "${csv_humana}" ]]; then
        log_error "CSV Humana vacío o no encontrado: ${csv_humana}"
        return
    fi
    if [[ ! -s "${csv_hongo}" ]]; then
        log_error "CSV Hongo vacío o no encontrado: ${csv_hongo}"
        return
    fi

    log_info "CSV Humana → ${csv_humana}"
    log_info "CSV Hongo  → ${csv_hongo}"

    python3 "${script_python}" \
        --csv_humana  "${csv_humana}" \
        --csv_hongo   "${csv_hongo}" \
        --output_dir  "${PROYECTO_DIR}" \
        && log_ok "Histogramas generados exitosamente en ${PROYECTO_DIR}/" \
        || log_warn "Error al generar histogramas (verifica dependencias Python)"
}

# =============================================================================
# SECCIÓN 9: PUNTO DE ENTRADA PRINCIPAL
# =============================================================================

main() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         CRIBADO VIRTUAL MASIVO — AUTODOCK VINA             ║"
    echo "║         Receptor Humana + Receptor Hongo                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    log_info "Proyecto en: ${PROYECTO_DIR}"
    log_info "CPU cores  : ${CPU_CORES}"
    log_info "Num modes  : ${NUM_MODES}"
    log_info "Exhaustiveness: ${EXHAUSTIVENESS}"
    echo "" >&2

    verificar_dependencias
    crear_estructura_directorios

    # ejecutar_cribado "humana" "${CONFIG_HUMANA}" "${RESULTADOS_HUMANA}"
    ejecutar_cribado "hongo"  "${CONFIG_HONGO}"  "${RESULTADOS_HONGO}"

    # CORRECCIÓN: capturar la ruta del CSV correctamente
    # extraer_scores ahora solo emite la ruta por stdout, los logs van por stderr
    # local CSV_HUMANA
    local CSV_HONGO
    # CSV_HUMANA=$(extraer_scores "${RESULTADOS_HUMANA}" "humana")
    CSV_HONGO=$(extraer_scores  "${RESULTADOS_HONGO}"  "hongo")

    # generar_histogramas "${CSV_HUMANA}" "${CSV_HONGO}"

    echo "" >&2
    log_header "CRIBADO COMPLETADO"
    # log_ok "Resultados humana  → ${RESULTADOS_HUMANA}/"
    log_ok "Resultados hongo   → ${RESULTADOS_HONGO}/"
    # log_ok "Scores humana      → ${CSV_HUMANA}"
    log_ok "Scores hongo       → ${CSV_HONGO}"
    log_ok "Errores            → ${LOG_ERRORES}"
    echo "" >&2
}

main "$@"
