#!/bin/bash
# N.Dzinalija VUmc 2023

# In order to harmonize processing across sites when merging the derivatives/halpipe folder
# we assign a site code and rename all subject folders and subject output files by appending code.
# This is done in the 1_convert_site_files_to_codes.sh script. Here we also extracted the contrasts that 
# we were interested in into separate folders that have all (and only) the data needed to run mega-analysis.
# We then need, for sites that have more than one session or run, to perform a group-level analysis on 
# the first-level stat effect maps of that subject using fsl_glm to arrive at a single statmap per 
# subject for this contrast of interest. Runs that failed QC have already been excluded in the 
# 2_exclude_failed_QC_subs.sh script so all that remain in the contrast folders may be used 

# CV 28-6-23 added some extra output and some notes but overall looks good


### Paths ####

INHIBITION=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/INHIBITION/halfpipe
ERROR=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/ERROR/halfpipe

# would make the fsl version more explicit. Although unlikely it is possible that newer versions of fsl will behave differently.
module load fsl/6.0.7.6

# Find all subjects that have multiple runs/sessions, then concatenate all effect maps for those subjects.
# Then find least common mask from the multiple runs/sessions, and use it in fsl_glm command, also creating
# design.mat and design.con files that fsl_glm will need.


for contrast in ${INHIBITION} ${ERROR}; do
    cd ${contrast}
    ls -d sub-* > ${contrast}/subjdirs.txt

    for sub in $(cat ${contrast}/subjdirs.txt); do
        if [[ $(find -L ${contrast}/${sub} -type f \( -name "*ses-*" -o -name "*run-*" \)) ]]; then
            echo ${sub}
            sessions=$(find -L ${contrast}/${sub} -type f -name "*ses-*effect_statmap.nii.gz" | sort -u)
            runs=$(find -L ${contrast}/${sub} -type f -name "*run-*effect_statmap.nii.gz" | sort -u)

            # sort not necessary here but also not wrong.
            num_sessions=$(echo ${sessions} | grep -o "ses[^/]*" | sort -u | wc -l)
            num_runs=$(echo ${runs} | grep -o "run[^/]*" | sort -u | wc -l)

            # extract info from filename
            if [ -z "$runs" ]; then
                filename=$(echo $sessions | awk '{print $1}')
                else
                filename=$(echo $runs | awk '{print $1}')
            fi
            task=$(echo "$filename" | sed -n 's/.*task-\([^_]*\).*/\1/p')
            feature=$(echo "$filename" | sed -n 's/.*feature-\([^_]*\).*/\1/p')
            taskcontrast=$(echo "$filename" | sed -n 's/.*taskcontrast-\([^_]*\).*/\1/p')
            
            # print to screen to be able to immediately spot errors
            echo
            echo " ------- " 
            echo " ${sub} "
            echo " ------- " 
            echo "task=${task}"
            echo "feature=${feature}"
            echo "contrast=${taskcontrast}"
            echo
            if [ ! -z "$sessions" ]; then
                echo "has ${num_sessions} session(s)"
            fi
            if [ ! -z "$runs" ]; then
                echo "has ${num_runs} run(s)"
            fi


            # merge sessions or runs and create design.mat file
            # Note: some subjects may have both session and run in filename, then both variables will be 
            # identical (have same nifti images), so which one is merged (sessions or runs) is irrelevant 
            if [[ ! -f ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-effect_statmap_concatenated.nii.gz || ! -f  ${contrast}/${sub}/design.mat ]]; then
                if [[ ${num_sessions} -gt 1 ]]; then
                    echo "Multiple sessions found. Performing fslmerge..."
                    fslmerge -t ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-effect_statmap_concatenated.nii.gz ${sessions}
                    printf '1\n%.0s' $(seq 1 ${num_sessions}) > ${contrast}/${sub}/design.mat
                fi

                if [[ ${num_runs} -gt 1 ]]; then
                    echo "Multiple runs found. Performing fslmerge..."
                    fslmerge -t ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-effect_statmap_concatenated.nii.gz ${runs}
                    printf '1\n%.0s' $(seq 1 ${num_runs}) > ${contrast}/${sub}/design.mat
                fi
            fi

            if [[ ${num_sessions} -gt 1 || ${num_runs} -gt 1 ]]; then
                # create design.con file (always identical)
                printf 1 > ${contrast}/${sub}/design.con

                # create mask that multiplies each subject's run/sessions masks 
                if [[ ! -f ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_mask_combined.nii.gz ]]; then
                    echo "Creating single mask file. Performing fslmaths..."
                    masks=$(find -L ${contrast}/${sub} -type f -name "*mask.nii.gz" | sort -u)
                    num_masks=$(echo ${masks[@]} | grep -o "sub[^/]*mask" | wc -w)

                    # merges them in time dimension than takes the minimum in the time dimension (least common mask)
                    fslmerge -t ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_masks_combined.nii.gz ${masks}
                    fslmaths ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_masks_combined.nii.gz \
                    -Tmin ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_mask_combined.nii.gz
                fi

                # run fsl_glm to create group-level intercept-only model for each subject
                if [ ! -f ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-z_statmap.nii.gz ]; then
                    echo "Aggregating runs/sessions at first level. Performing fsl_glm..."
                    fsl_glm -i ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-effect_statmap_concatenated.nii.gz \
                        -d ${contrast}/${sub}/design.mat \
                        -c ${contrast}/${sub}/design.con \
                        -m ${contrast}/${sub}/${sub}*mask_combined.nii.gz \
                        --out_z=${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-z_statmap.nii.gz \
                        --out_cope=${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-effect_statmap.nii.gz \
                        --out_varcb=${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-variance_statmap.nii.gz
                fi

                # create effect_statmap.json file to include mean framewise displacement info of all runs/sessions
                jfile=${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-effect_statmap.json
                meanFDMean=$(cat ${contrast}/${sub}/*.json | jq -r '.FDMean' | awk '{ sum += $1; count++ } END { print sum / count }')
                meanFDPerc=$(cat ${contrast}/${sub}/*.json | jq -r '.FDPerc' | awk '{ sum += $1; count++ } END { print sum / count }')
                jq -n --arg meanFDMean "$meanFDMean" '{"FDMean": ($meanFDMean | tonumber)}' > ${jfile}
                echo "$(jq --arg meanFDPerc "${meanFDPerc}" '. += {"FDPerc": ($meanFDPerc | tonumber) }' ${jfile})" > ${jfile}

                # if there is a model_aggregate remove the session- and run-specific first-level output
                if [ -f ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_stat-z_statmap.nii.gz ]; then
                    rm -f ${contrast}/${sub}/${sub}*ses* 
                    rm -f ${contrast}/${sub}/${sub}*run* 
                    rm -f ${contrast}/${sub}/${sub}*stat-effect_statmap_concatenated.nii.gz

                    # rename combined mask file to make it findable for HALFpipe's group-level 
                    mv ${contrast}/${sub}/${sub}*mask_combined.nii.gz ${contrast}/${sub}/${sub}_task-${task}_feature-${feature}_taskcontrast-${taskcontrast}_mask.nii.gz
                    rm -f ${contrast}/${sub}/${sub}*masks*
                fi
            fi
        fi
    done
            
done