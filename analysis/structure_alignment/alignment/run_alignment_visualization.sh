#!/bin/bash

# Example script to run the complete PI3K visualization workflow.
# Usage: bash run_alignment_visualization.sh

echo "=========================================="
echo "PI3K ALIGNMENT VISUALIZATION"
echo "=========================================="
echo ""

# Switch to the workflow directory itself.
cd "$(dirname "${BASH_SOURCE[0]}")"

# Step 1: Check the required files.
echo "[1/4] Checking required files..."
if [ -f "superimpose_pi3k_pdb.tcl" ] && \
   [ -f "superimpose_pi3k_pdb.input" ] && \
   [ -f "model05.pdb" ] && \
   [ -f "7RSP.pdb" ]; then
    echo "  All required files were found."
else
    echo "  Missing one or more required files."
    exit 1
fi

echo ""
echo "[2/4] Running the Tcl superposition script..."
echo "  Command: vmd -dispdev text -e superimpose_pi3k_pdb.tcl"
echo ""

# Execute the Tcl script.
vmd -dispdev text -e superimpose_pi3k_pdb.tcl

echo ""
echo "[3/4] Verifying generated results..."
if [ -f "7RSP_sup.pdb" ] && [ -f "superimpose_pi3k_pdb.rmsd.out" ]; then
    echo "  Superposed structure generated: 7RSP_sup.pdb"
    echo "  RMSD file generated: superimpose_pi3k_pdb.rmsd.out"

    # Read and display the RMSD value.
    rmsd_value=$(awk '{print $2}' superimpose_pi3k_pdb.rmsd.out)
    echo ""
    echo "  RMSD RESULT: $rmsd_value Å"
    if (( $(echo "$rmsd_value < 1.0" | bc -l) )); then
        echo "     EXCELLENT (< 1.0 Å)"
    elif (( $(echo "$rmsd_value < 2.0" | bc -l) )); then
        echo "     GOOD (1-2 Å)"
    else
        echo "     MODERATE (> 2.0 Å)"
    fi
else
    echo "  Result files were not generated."
    exit 1
fi

echo ""
echo "[4/4] Opening the visualization in VMD..."
echo "  Structure 0: 7RSP.pdb (human)"
echo "  Structure 1: 7RSP_sup.pdb (aligned fungal model)"
echo ""
echo "  VMD CONTROLS:"
echo "    - Left mouse + drag: rotate"
echo "    - Mouse wheel: zoom"
echo "    - Right mouse + drag: translate"
echo ""
echo "  TCL CONSOLE COMMANDS:"
echo "    source reps.tcl          # Apply representations"
echo "    mol off 0                # Hide molecule 0"
echo "    mol off 1                # Hide molecule 1"
echo ""

# Launch VMD with both structures.
vmd 7RSP.pdb 7RSP_sup.pdb &

echo ""
echo "=========================================="
echo "VMD OPENED - Press Ctrl+C to exit"
echo "=========================================="
