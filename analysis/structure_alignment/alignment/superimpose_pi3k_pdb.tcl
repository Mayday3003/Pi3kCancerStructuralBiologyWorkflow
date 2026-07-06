# Superponer sitios catalíticos de PI3K
#
# Comando en consola:  vmd -dispdev text -e superimpose_pi3k_pdb.tcl
#
# Cada estructura se superpone a una estructura de referencia
# La superposición se hace para los C-alfa de conjuntos de aminoácidos
# definidos por segmentos de secuencia, dados como datos de entrada.
# Esta solución permite lidiar con las diferencias de numeración en las
# secuencias.
#
# --------------------------------------------------------------------
#
# File de datos de entrada:
#
# La primera línea contiene:
#  "nfiles=" nfiles : numero de estructuras PDB a superponer, listadas a partir de la siguiente línea
# 
# Sea "nseg": número de segmentos de secuencia a utilizar en la superposición
#
# Cada línea a continuacion contiene (separados por espacios):
# - PDB file code
# - identificador de la cadena a superponer
# - "nseg" segmentos de secuencia
#
# La primera estructura se usará como referencia para superponer
# las restantes.
#


# Abrir fichero de datos de entrada: pi3k_pdb.input
# Abrir fichero de salida
# Leer y guardar número de files y número de strings de secuencia

set pdbdir "."

set inputfile [open superimpose_pi3k_pdb.input r]

set outfile   [open superimpose_pi3k_pdb.rmsd.out w]


# Leer primera linea y guardar  variable 'nfiles'
gets $inputfile line
# Lee 2do argumento
set nfiles [lindex $line 1]

#Leer segunda línea y guardar datos de la estructura de referencia:
#- pdbref
#- chainref
#- seqref1, seqref2, seqref3, seqref4, seqref5
gets $inputfile line
set pdbref [lindex $line 0]
set chainref [lindex $line 1]
set seqref1 [lindex $line 2]
set seqref2 [lindex $line 3]
set seqref3 [lindex $line 4]
set seqref4 [lindex $line 5]
set seqref5 [lindex $line 6]


# Definición de los átomos de referencia para la superposición

mol load pdb $pdbdir/$pdbref.pdb

set referencia [atomselect [molinfo index 0] "chain $chainref and name CA and (sequence $seqref1  $seqref2  $seqref3  $seqref4  $seqref5 )" ]


#
# Ciclo por la lista de estructuras
#

for {set i 1} { $i < $nfiles} {incr i} {

   #Leer siguiente linea y guardar datos:
   #- pdbcode
   #- pdbchain
   #- seq1, seq2, seq3, seq4, seq5

   gets $inputfile line
   set pdbcode [lindex $line 0]
   set pdbchain [lindex $line 1]
   set seq1 [lindex $line 2]
   set seq2 [lindex $line 3]
   set seq3 [lindex $line 4]
   set seq4 [lindex $line 5]
   set seq5 [lindex $line 6]


   mol load pdb $pdbdir/$pdbcode.pdb

   set seleccion [atomselect [molinfo index 1] "chain $pdbchain  and  name CA  and (sequence $seq1 $seq2 $seq3 $seq4 $seq5)" ]

   set transformation_mat [measure fit $seleccion $referencia]

   set move_sel [atomselect [molinfo index 1] "all"]

   $move_sel move $transformation_mat


   set rmsd0 [measure rmsd $seleccion $referencia]

   puts $outfile "${pdbcode}_${pdbchain}    $rmsd0"

   set writesel [atomselect [molinfo index 1] "all"]
   $writesel writepdb ${pdbcode}_sup.pdb
   ##

   # Borrar la molécula ya analizada

   mol delete [molinfo index 1]

}


close $inputfile
close $outfile

exit







