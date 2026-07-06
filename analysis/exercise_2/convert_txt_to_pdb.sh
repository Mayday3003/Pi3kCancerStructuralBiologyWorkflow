#!/bin/bash

mkdir -p resultados_pdb

for input_file in *.txt; do
    obabel "$input_file" -isdf -opdb -O "resultados_pdb/${input_file%.txt}.pdb"
    echo "Processed: $input_file"
done

echo "Done. Files saved in 'resultados_pdb'."