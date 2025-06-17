#!/bin/bash
# N.Dzinalija VUmc 2023

# Based on visual QC some subjects have been marked for exclusion, either the entire subject (for example if skullstripping failed)
# or just one run (if rest could be salvaged). These are in failed_QC.txt in each contrast folder, they are read in and the subjects/runs
# are removed from the contrast folders before fsl_glm is used to aggregate across runs and further processing occurs.

# In addition, runs with mean FD > 1.0 mm (cutoff) are removed and written to failed_FD1.0.txt

INHIBITION=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/INHIBITION
ERROR=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/ERROR

for contrast in ${INHIBITION} ${ERROR}; do
    failed_QC=${contrast}/failed_QC.txt
    excludedFD=${contrast}/failed_FD1.0.txt
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
            if [ -d ${contrast}/halfpipe/${sub} ]; then
                runExists=$(find -L ${contrast}/halfpipe/${sub} -type f -name "*run-${run}*")
                if [ -n "$runExists" ]; then 
                    echo " Removing run: ${run} from ${sub} for contrast $(basename $contrast)"
                    rm -r ${contrast}/halfpipe/${sub}/*run-${run}*
                fi    
            fi
        fi
    done

  ### Read FD values from .json effect files to 
  ### identify subjects who had too much motion 
  ### and remove them 
    echo -e "Subject\tRun\tFD" > ${excludedFD}

    cd ${contrast}/halfpipe

    for sub in sub-*; do
        for jsonfile in ${sub}/*effect_statmap.json; do
            if [ -n ${jsonfile} ]; then
                fdmean=$(jq '.FDMean' ${jsonfile})
                    
                if (( $(echo "$fdmean > 1.0" | bc -l) )); then
                    run_id=$(basename "$jsonfile" | sed -n 's/.*run-\([^_]*\)_feature.*/\1/p')
                    echo -e "${sub}\t${run_id}\t${fdmean}" >> ${excludedFD}
                fi
            fi
        done
    done

    echo "excluding subs with FD greater than 1.0mm"

    # Read the failed_FD1.0.txt file line by line
    tail -n +2 ${excludedFD} | while IFS=$'\t' read -r sub run fd; do

        # Check if Runs is empty
        if [ -z "$run" ]; then
            # Remove the directory with the subject ID if it exists
            if [ -d ${contrast}/halfpipe/${sub} ]; then 
                echo " Removing directory: ${sub} for contrast $(basename $contrast)"
                rm -r ${contrast}/halfpipe/${sub}
            fi
        else
            # Remove the specific run within the subject's directory if it exists
            if [ -d ${contrast}/halfpipe/${sub} ]; then
                runExists=$(find -L ${contrast}/halfpipe/${sub} -type f -name "*run-${run}*")
                if [ -n "$runExists" ]; then
                    echo " Removing run: ${run} from ${sub} for contrast $(basename $contrast)"
                    rm -r ${contrast}/halfpipe/${sub}/*run-${run}*
                fi
            fi
        fi
    done

    # Final cleanup: remove subject directories if they are now empty
    for sub in sub-*; do
        # Check if directory contains any NIfTI or JSON files (excluding dotfiles)
        file_count=$(find -L "$sub" -type f \( -name "*.nii.gz" -o -name "*.json" \) | wc -l)

        if [ "$file_count" -eq 0 ]; then
            echo " Removing now-empty directory: ${sub} for contrast $(basename $contrast)"
            rm -r ${contrast}/halfpipe/${sub}
        fi    
    done
done
