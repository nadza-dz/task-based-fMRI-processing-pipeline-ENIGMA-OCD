#!/bin/bash

### N.Dzinalija VUmc 2023
### After 7_create_RBA_input_models.R has run, the 8-3a_syntax_RBA_ROI_whole-brain.sh script is run 
### for each model of each contrast

scriptdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/scripts/tb_mega_pipeline/

for atlas in 200; do

        for contrast in INHIBITION ERROR; do

            for model in BASE YBOCS AO MED; do

                for group in ADULT PED SST ABCD; do 

                    sbatch --output RBA_Schaefer${atlas}_${contrast}_${model}_${group}.log ${scriptdir}/8-3a_syntax_RBA_whole-brain.sh ${contrast} ${model} ${group} ${atlas}

                done

            done

        done

done
