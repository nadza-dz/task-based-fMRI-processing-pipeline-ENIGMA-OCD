#!/bin/bash

### N.Dzinalija VUmc 2023
### After 7_create_RBA_input_models.R has run, the 8-1a_syntax_RBA_ROI.sh script is run 
### for each contrast and model using this script. 

scriptdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/scripts/tb_mega_pipeline/
for contrast in INHIBITION ERROR; do

for group in ADULT PED SST ABCD; do

        for model in BASE YBOCS AO MED; do

            sbatch --output RBA_${contrast}_${model}_${group}.log ${scriptdir}/8-1a_syntax_RBA_ROI.sh ${contrast} ${model} ${group} 

        done
    done
done
