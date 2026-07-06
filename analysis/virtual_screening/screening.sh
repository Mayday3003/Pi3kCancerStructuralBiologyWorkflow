DB_LIGANDOS="/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/DB_1000m"
OUTPUT_DIR="./resultados_hongo"
CONFIG_FILE="./configs/vina_config_honguito.txt"



while IFS= read -r -d '' ligando_path; do

    ligando_basename=$(basename "${ligando_path}" .pdbqt)
    out_pdbqt="${OUTPUT_DIR}/${ligando_basename}_out.pdbqt"
    out_log="${OUTPUT_DIR}/${ligando_basename}.log"

    vina \
        --config    "${CONFIG_FILE}"   \
        --ligand    "${ligando_path}"  \
        --out       "${out_pdbqt}"     \
        --log       "${out_log}"       \
        --cpu       15                 \
        --num_modes 1                  \
        >> "${out_log}" 2>&1


done < <(find "${DB_LIGANDOS}" -maxdepth 1 -name "*.pdbqt" -print0 | sort -z)