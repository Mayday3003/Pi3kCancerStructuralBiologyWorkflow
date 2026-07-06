# Ejercicio 4: Cómo Ejecutar la Visualización de Superposición de Estructuras PI3K

## 📋 Resumen

Este documento explica cómo ejecutar la visualización de la superposición de estructuras 3D de PI3K humana y fúngica usando el script TCL y VMD.

---

## 🎯 Objetivos

- ✅ Ejecutar el script de superposición (`superimpose_pi3k_pdb.tcl`)
- ✅ Verificar que se generó la estructura superposicionada (`7RSP_sup.pdb`)
- ✅ Visualizar las estructuras en VMD
- ✅ Aplicar representaciones visuales
- ✅ Analizar el resultado (RMSD = 0.8951 Å)

---

## 🚀 Instrucciones de Ejecución

### **Opción A: Ejecución sin GUI (Recomendada para pruebas rápidas)**

1. **Abra una terminal** y navegue al directorio:
```bash
cd /home/Mayday3003/Downloads/mari
```

2. **Ejecute el script TCL:**
```bash
vmd -dispdev text -e superimpose_pi3k_pdb.tcl
```

3. **Qué sucede:**
   - VMD se abre en modo "headless" (sin interfaz gráfica)
   - El script carga `model05.pdb` (referencia, fúngico)
   - El script carga `7RSP.pdb` (estructura a superponer, humano)
   - Calcula la matriz de transformación basada en C-alfa del sitio activo
   - Aplica la transformación a la estructura humana
   - Calcula RMSD = 0.8951 Å
   - Genera: `7RSP_sup.pdb` (estructura superposicionada)
   - Escribe resultado en: `superimpose_pi3k_pdb.rmsd.out`

4. **Duración:** ~5-10 segundos

5. **Verificar resultado:**
```bash
ls -lh *.pdb *.out
```

Deberías ver:
```
-rw-r--r-- model05.pdb
-rw-r--r-- 7RSP.pdb
-rw-r--r-- 7RSP_sup.pdb          ← Archivo generado (nueva estructura)
-rw-r--r-- superimpose_pi3k_pdb.rmsd.out  ← Resultado RMSD
```

---

### **Opción B: Visualización Interactiva en GUI (Recomendada para análisis)**

#### **Paso 1: Abrir VMD y cargar estructuras**

```bash
cd /home/Mayday3003/Downloads/mari
vmd 7RSP.pdb 7RSP_sup.pdb &
```

Esto abre VMD con dos moléculas:
- **Molécula 0:** 7RSP.pdb (estructura humana original)
- **Molécula 1:** 7RSP_sup.pdb (estructura fúngica superposicionada)

#### **Paso 2: Interactuar con la visualización**

En la **ventana OpenGL** de VMD:

| Acción | Botón/Tecla | Efecto |
|--------|-------------|--------|
| Rotar | Mouse izq + mover | Rota la proteína |
| Zoom | Rueda del ratón | Acerca/aleja |
| Traducir | Mouse derecho + mover | Desplaza |
| Inicio | Botón central | Centra la vista |

#### **Paso 3: Aplicar representaciones visuales**

En la **Tk Console** de VMD (ventana negra con ">" ):

```tcl
# Ejecutar el script de representaciones
source reps.tcl
```

Este comando:
- Elimina representaciones anteriores
- Añade representación "Lines" (esqueleto de C-alfa) coloreado
- Añade representación "Licorice" (heteroátomos/ligandos)

#### **Paso 4: Análisis Visual**

Para resaltar el sitio activo:

```tcl
# Seleccionar átomos CA del sitio activo
set active_site [atomselect top "name CA and (sequence GDDLR KENLD LATST SCAGY DFGYI)"]

# Colorear de rojo
$active_site color red

# Mostrar como esferas
$active_site representation spheres

# Aumentar tamaño
$active_site set radius 0.5
```

Para mostrar/ocultar moléculas:

```tcl
# Mostrar solo molécula 0 (humana)
mol off 1
mol on 0

# Mostrar solo molécula 1 (fúngica superposicionada)
mol off 0
mol on 1

# Mostrar ambas
mol on 0
mol on 1
```

---

### **Opción C: Ejecución Completa (Script + Visualización)**

```bash
cd /home/Mayday3003/Downloads/mari

# 1. Generar estructura superposicionada
vmd -dispdev text -e superimpose_pi3k_pdb.tcl
echo "✓ Superposición completada"

# 2. Visualizar resultado
vmd 7RSP.pdb 7RSP_sup.pdb
# En la consola: source reps.tcl
```

---

## 📊 Interpretación de Resultados

### **RMSD = 0.8951 Å**

| Métrica | Valor | Significado |
|---------|-------|------------|
| **RMSD** | 0.895 Å | **EXCELENTE** ✅ |
| **Rango de referencia** | < 1.0 Å | Estructuras casi idénticas |
| **Conclusión** | Sitio activo conservado | Modelado por homología exitoso |

### **¿Qué significa?**

- ✅ El sitio catalítico del modelo fúngico está perfectamente alineado
- ✅ Las conformaciones 3D de ambas proteínas son muy similares
- ✅ El modelo de Swiss-Model es de alta calidad para esta región
- ✅ Los inhibidores de PI3K humana probablemente funcionen en el hongo

---

## 🔧 Archivos Utilizados

| Archivo | Descripción |
|---------|------------|
| `superimpose_pi3k_pdb.tcl` | Script TCL que ejecuta la superposición |
| `superimpose_pi3k_pdb.input` | Archivo de configuración (PDB IDs, cadenas, segmentos) |
| `model05.pdb` | Modelo fúngico (Swiss-Model) |
| `7RSP.pdb` | Estructura cristalográfica humana (referencia) |
| `7RSP_sup.pdb` | **GENERADO:** Estructura humana superposicionada |
| `superimpose_pi3k_pdb.rmsd.out` | **GENERADO:** Valor de RMSD |
| `reps.tcl` | Script de representaciones visuales |

---

## 💡 Comandos TCL Útiles (Referencia)

### En la Tk Console de VMD:

```tcl
# Información sobre moléculas cargadas
molinfo num

# Listar átomos de una selección
set sel [atomselect 0 "name CA"]
$sel get {resname resid x y z}

# Calcular distancia entre dos átomos
measure bond {atom1_index atom2_index}

# Exportar imagen
render Tachyon out.dat -o out.tga

# Limpiar memoria
mol delete all
```

---

## ❓ Preguntas Frecuentes

**P: ¿Por qué el RMSD es importante?**
R: Un RMSD bajo indica que el modelo 3D fúngico generado por Swiss-Model es de buena calidad y estructuralmente similar al de la proteína humana cristalográfica.

**P: ¿Qué pasa si ejecuto `reps.tcl` pero no veo cambios?**
R: Asegúrate de que las moléculas están cargadas (`vmd 7RSP.pdb 7RSP_sup.pdb`) y que estás en la consola Tk de VMD (ventana negra).

**P: ¿Puedo usar estos scripts en otras proteínas?**
R: Sí, edita `superimpose_pi3k_pdb.input` con otros PDB IDs, cadenas y segmentos de secuencia.

**P: ¿Qué necesito instalar?**
R: Solo VMD (http://www.ks.uiuc.edu/Research/vmd/). Está preinstalado en la mayoría de sistemas con Python/Anaconda.

---

## 📚 Referencias

- **VMD:** http://www.ks.uiuc.edu/Research/vmd/
- **PDB:** https://www.rcsb.org/
- **Swiss-Model:** https://swissmodel.expasy.org/
- **RMSD:** métrica estándar en bioinformática estructural

---

## 📝 Notas para la Presentación en Clase

1. **Mostrar el comando:**
   ```bash
   vmd -dispdev text -e superimpose_pi3k_pdb.tcl
   ```

2. **Explicar qué hace:**
   - Carga dos estructuras PDB en memoria
   - Selecciona residuos específicos del sitio catalítico
   - Calcula la transformación geométrica óptima
   - Aplica la transformación
   - Calcula la desviación (RMSD)

3. **Mostrar el resultado:**
   - Archivo generado: `7RSP_sup.pdb`
   - RMSD: **0.8951 Å** (excelente)

4. **Interpretación:**
   - Sitio activo muy conservado
   - Estructura 3D muy similar
   - Modelado por homología fue exitoso

---

**Última actualización:** Mayo 2026  
**Para:** Presentación del Ejercicio 4 en Clase
