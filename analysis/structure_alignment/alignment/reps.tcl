# Create molecule representations

for {set i 0} { $i< [molinfo num]} {incr i} {

    # Delete any previous representations

    set numRep [molinfo $i get numreps]
    for {set j 0} {$j<$numRep} {incr j} {
      mol delrep [expr {($numRep-1) - $j}] [molinfo index $i]
    }
     
    # Representations

    mol representation Lines 1.0 
    mol color ColorID $i
    mol selection "name N CA C"
    mol addrep [molinfo index $i]
    mol showrep [molinfo index $i] 0 on

    mol representation Licorice 0.3
    mol color ColorID $i
    mol selection "hetero and not water"
    mol addrep [molinfo index $i]
    mol showrep [molinfo index $i] 1 on

}
