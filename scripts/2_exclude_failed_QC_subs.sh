#!/bin/bash
# N.Dzinalija VUmc 2023

# Based on visual QC some subjects have been marked for exclusion, either the entire subject (for example if skullstripping failed)
# or just one run (if rest could be salvaged). These are in failed_QC.txt in each contrast folder, they are read in and the subjects/runs
# are removed from the contrast folders before fsl_glm is used to aggregate across runs and further processing occurs.

INHIBITION=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/INHIBITION
ERROR=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/ERROR

for contrast in ${INHIBITION} ${ERROR}; do
    failed_QC=${contrast}/failed_QC.txt
    dos2unix ${failed_QC}

    # Read the failed_QC.txt file line by line
    tail -n +2 ${failed_QC} | while IFS=$'\t' read -r sub run; do

        # Check if Runs is empty
        if [ -z "$run" ]; then
            # Remove the directory with the subject ID if it exists
            if [ -d ${contrast}/halfpipe/${sub} ]; then 
                echo " Removing directory: ${sub} for contrast $(basename $contrast)"
                rm -r ${contrast}/halfpipe/${sub}
            fi
        else
            # Remove the specific run within the subject's directory if it exists
            runExists=$(find -L ${contrast}/halfpipe/${sub} -type f -name "*run-${run}*")
            if [ -n "$runExists" ]; then 
                echo " Removing run: ${run} from ${sub} for contrast $(basename $contrast)"
                rm -r ${contrast}/halfpipe/${sub}/*run-${run}*
            fi
        fi
    done

done