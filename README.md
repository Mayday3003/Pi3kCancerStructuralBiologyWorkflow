# PI3K Docking and Virtual Screening

This repository documents a PI3K structural biology workflow, including docking validation, structural alignment, and virtual screening against human and fungal targets.

## Compact Layout

- `analysis/` - all workflow folders, notebooks, and analysis artifacts
- `data/` - reference structures, images, FASTA files, and model outputs
- `info.ipynb` - main notebook that compiles the project narrative and results

## Inside `analysis/`

- `analysis/exercise_1/` - ligand and structure preparation for the first exercise
- `analysis/exercise_2/` - file conversion and preparation utilities for docking inputs
- `analysis/docking_comparisons/` - docking comparison against the crystallographic reference ligand
- `analysis/structure_alignment/` - structural alignment, mutation analysis, and visualization
- `analysis/fungal_docking/` - docking of fungal models against the selected ligands
- `analysis/virtual_screening/` - virtual screening workflow and score comparison
- `analysis/explanations/` - extra figures and explanation notebook material

## Inside `data/`

- `data/resources/` - source FASTA files and supporting reference material
- `data/fungal_folding_models/` - homology-model outputs for the fungal protein
- `data/images/` - figures used across the notebooks and reports
- `data/pdbs/` - curated PDB structures and intermediate structural files
- `data/docking/` - supporting ligand docking inputs

## Main Files

- `analysis/exercise_1/convert_sdf_to_pdb.sh` - converts `.sdf` inputs to `.pdb`
- `analysis/exercise_2/convert_txt_to_pdb.sh` - converts ligand text files to `.pdb`
- `analysis/structure_alignment/alignment/run_alignment_visualization.sh` - runs the PI3K alignment visualization workflow
- `analysis/virtual_screening/screening/run_screening.sh` - runs the virtual screening pipeline with logs

## Notes For GitHub

- The root is intentionally compact: the project content now lives under `analysis/` and `data/`.
- The exercise numbering is preserved inside `analysis/` because it matches the original project flow.
- The top-level tree is now easier to scan, while the scientific folders keep their original internal organization.

