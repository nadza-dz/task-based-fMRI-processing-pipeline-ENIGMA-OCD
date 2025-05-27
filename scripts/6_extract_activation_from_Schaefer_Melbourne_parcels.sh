#!/bin/bash
# N.Dzinalija VUmc 2023

### Extract regions from Melbourne Scale 2 subcortical atlas and Schaefer 200 parcel atlas in MNI2009 space from subject first-level z-stat files.
### Then create RBA input file with all demographic data, filtering out parcels with insufficient signal (<30%) and subjects with too much motion.
### NOTE: don't worry about "ERROR:: Empty mask image" appearing in output, it simply means one region has no surviving voxels (very common)

#SBATCH --job-name=Schaefer
#SBATCH --mem=8G
#SBATCH --partition=luna-cpu-long
#SBATCH --qos=anw-cpu
#SBATCH --cpus-per-task=4
#SBATCH --time=01-0:00:00


module load fsl

mergedir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged
demographic_file=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/covariates/RBA_input_demographics_only.csv
dos2unix ${demographic_file}

for atlas in 200; do 

    atlasfile=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Emotional_domain/ROIs/Schaefer_cortical_Melbourne_subcortx/Schaefer_${atlas}/Schaefer2018_${atlas}Parcels_7Networks_order_Tian_Subcortex_S2_3T_MNI152NLin2009cAsym_2mm.nii.gz
    roiorder=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Emotional_domain/ROIs/Schaefer_cortical_Melbourne_subcortx/Schaefer_${atlas}/Schaefer${atlas}_S2_labels.txt
    roivolume=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Emotional_domain/ROIs/Schaefer_cortical_Melbourne_subcortx/Schaefer_${atlas}/Schaefer${atlas}_S2_volumes.txt
    dos2unix ${roiorder}
    dos2unix ${roivolume}

    for contrast in INHIBITION ERROR; do
        
        excludedFD=${mergedir}/${contrast}/failed_FD1.0.txt 
        inputdir=${mergedir}/${contrast}/halfpipe
        mkdir -p ${mergedir}/${contrast}/Schaefer${atlas}_extracted_z-values
        ROIdir=${mergedir}/${contrast}/Schaefer${atlas}_extracted_z-values

        #####################################
        ### Begin extracting activations  ###
        #####################################

        echo "Extracting ROI activations..."

        #read the ROI order txt file into an array
        mapfile -t roinames <${roiorder}

        cd ${inputdir}

        for subj in $(ls -d sub-*); do
            echo ${subj}
            cd ${inputdir}/${subj}

            Zstatsfile=$(ls -1 *stat-z_statmap.nii.gz | head -1)
            
            if [ -f ${Zstatsfile} ]; then 
                if [ ! -f ${ROIdir}/${subj}_${contrast}.txt ]; then
                    #extract activation from parcels and volume of surviving voxels to a txt file
                    activations=$(fslstats -K ${atlasfile} ${inputdir}/${subj}/${Zstatsfile} -M)
                    volumes=$(fslstats -K ${atlasfile} ${inputdir}/${subj}/${Zstatsfile} -V | awk '{printf "%.0f\n", $2}')
                    output=$(paste -d " " <(printf "%s\n" "${roinames[@]}") <(printf "%s\n" "$activations") <(printf "%s\n" "$volumes"))
                    echo "${output}" >${ROIdir}/${subj}_${contrast}.txt
                fi 
            fi

            # clear variables to ensure they don't end up in other subjects' txt files
            unset output activations volumes Zstatsfile
        done

        ##############################
        ### Create RBA input file  ###
        ##############################
        
        echo "Creating RBA input file..."  

        RBA_input=RBA_input_${contrast}_Schaefer${atlas}.txt
        cd ${ROIdir}
        rm -f ${ROIdir}/${RBA_input}

        # Loop through all ROI activation files in the directory
        if [ ! -f ${ROIdir}/${RBA_input} ]; then
            for file in ${ROIdir}/sub-*.txt; do
                subject_name=$(basename ${file} _${contrast}.txt)
                echo $subject_name

                if grep -q ",${subject_name}," ${demographic_file}; then
                    # Get the demographic data for the current subject
                    sample=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $1}' ${demographic_file})
                    task=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $3}' ${demographic_file})
                    agegroup=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $4}' ${demographic_file})
                    diagnosis=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $5}' ${demographic_file})
                    sex=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $8}' ${demographic_file})
                    age=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $7}' ${demographic_file})
                    ybocs=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $6}' ${demographic_file})
                    med=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $10}' ${demographic_file})
                    onset=$(awk -F',' -v subj="$subject_name" '$2 == subj {print $9}' ${demographic_file})

                    # Check if subject has minimum necessary data
                    if [[ -n $age && -n $sex ]]; then
                        # Add the subject name, ROI name, ROI volume, ROI activation, and demographic data to each row
                        paste -d ',' <(printf "$subject_name\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$sample\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$agegroup\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$task\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$diagnosis\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$sex\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$age\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$ybocs\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$med\n%.0s" $(seq $(wc -l <${file}))) \
                            <(printf "$onset\n%.0s" $(seq $(wc -l <${file}))) \
                            <(awk '{print $1}' ${file}) \
                            <(awk '{print $2}' ${file}) \
                            <(awk '{print $3}' ${file}) \
                            >>${ROIdir}/${RBA_input}
                        # clear variables to ensure they don't end up in other subjects' txt files
                        unset sample task agegroup diagnosis sex age ybocs med onset
                    else
                        echo "$subject_name is missing age or sex variables"
                    fi
                else 
                    echo "$subject_name is not present in demographic file"
                fi
            done
        fi

        ##############################
        ### Clean RBA input file  ###
        ##############################

        echo "Cleaning up RBA input file..."

        # Read the contents of ROIs_volume.txt into an associative array
        declare -A roi_volumes
        while read -r key value; do
            roi_volumes[$key]=$value
        done < <(awk '{print $1, $3}' ${roivolume})

        # Read the contents of RBA_input.txt into an array
        mapfile -t personalized_ROI_values <${ROIdir}/${RBA_input}
        > ${ROIdir}/../insufficient_volume_parcels_${contrast}.txt

        # Create a temporary file to store the filtered output later
        temp_file=${ROIdir}/temp.txt

        # Add the column names to the output file
        echo "Subj,Sample,AGEGROUP,TASK,Dx,SEX,AGE,YBOCS,MED,AO,ROI,Y,Vol" >${temp_file}

        # Iterate over the parcels in RBA_input and compare voxel volumes to original parcels
        # Remove parcels where at least 30% of voxels do not have signal
        for i in "${!personalized_ROI_values[@]}"; do
            while IFS=',' read -r Subj Sample AGEGROUP TASK Dx SEX AGE YBOCS MED AO ROI Y Vol; do
                # Get the volume from the corresponding key in roi_volumes
                echo $Subj
                roi_volume=${roi_volumes[$ROI]}

                # Calculate the threshold as 30% of the ROI volume
                threshold=$(awk "BEGIN {print $roi_volume * 0.3}")

                # Compare the subject's ROI volume with the 30% threshold
                if awk -v a=$Vol -v b=$threshold 'BEGIN { if (a < b) exit 0; exit 1 }'; then
                    echo "${Subj}'s ${ROI} has a volume of ${Vol} mm3 which is less than 30% of total ROI volume (= ${roi_volume} mm3) surviving" >> ${ROIdir}/../insufficient_volume_parcels_${contrast}.txt
                    # Replace personal_ROI_vol with "NaN"
                    Y="NaN"
                fi

                # Append the modified line to the temporary file
                echo "${Subj},${Sample},${AGEGROUP},${TASK},${Dx},${SEX},${AGE},${YBOCS},${MED},${AO},${ROI},${Y},${Vol}" >>"${temp_file}"
            done <<<"${personalized_ROI_values[i]}"
        done

        # Replace the original RBA_input.txt file with the filtered contents
        mv ${temp_file} ${ROIdir}/${RBA_input}

        # Remove volume variable from RBA_input.txt
        awk -F, 'BEGIN {OFS=","} {NF--; print}' ${ROIdir}/${RBA_input} >${temp_file}
        mv ${temp_file} ${ROIdir}/${RBA_input}

        # Remove the subjects who had too much motion and are excluded according to 1.0 FD thresshold
        grep "^sub-" ${excludedFD} | while read -r line; do 
            subject=$(echo "$line" | awk '{print $1}')
            sed -i "/^${subject}\b/d" ${ROIdir}/${RBA_input}
        done <${excludedFD}

    done

done
