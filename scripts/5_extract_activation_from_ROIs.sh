#!/bin/bash
# N.Dzinalija VUmc 2023

### Once ROIs have been created using Melbourne subcortical atlas and 4_make_spheres_MNI2009.sh script
### 1) Create atlas file that is then used to extract activation per ROI. For LOAD contrast in Executive domain
###    atlas still needed to be manually adjusted in script due to multiple MNI coordinates per ROI. 
### 2) Identify subjects with too much motion. 
### 3) Extract activation from both cortical spheres and subcortical ROIs.
### 4) Create RBA input file with all demographic data, filtering out ROIs with insufficient signal 
###    (<30%) and subjects with too much motion.

# CV - 28-06-2023 made some small modifications and added a 'clear variables part' to ensure that if one iteration of the loop fails the
# output of the previous run doesn't get written to output of the wrong subject


module load fsl

mergedir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged
demographic_file=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/covariates/RBA_input_demographics_only.csv
dos2unix ${demographic_file}

####################################
### Extract activation from ROIs ###
####################################

for contrast in INHIBITION ERROR; do

  roisdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/ROIs/${contrast}
  roiorder=${roisdir}/ROIs_order.txt
  roivolume=${roisdir}/ROIs_volume.txt

  dos2unix ${roiorder}
  dos2unix ${roivolume}

  atlasfile=${roisdir}/All_combined/3D_atlas_*ROIs.nii.gz

  ##################################################
  ### Read FD values from .json effect files to ####
  ### identify subjects who had too much motion ####
  ##################################################
  
  excludedFD=${mergedir}/${contrast}/failed_FD1.0.txt 
  if [ ! -f "${excludedFD}" ]; then
    echo "Subject FD" > "$excludedFD"

    cd ${mergedir}/${contrast}/halfpipe
    for sub in sub-*; do
      jsonfile="${sub}/*effect_statmap.json"

      if [ -f ${jsonfile} ]; then
        fdmean=$(jq '.FDMean' ${jsonfile})
            
        if (( $(echo "$fdmean > 1.0" | bc -l) )); then
          echo "$sub $fdmean" >> ${excludedFD}
        fi
      fi
    done
  fi

  #####################################
  ### Begin extracting activations  ###
  #####################################
  
  echo "Extracting ROI activations..."
  
  #read the ROI order txt file into an array
  mapfile -t roinames <${roiorder}

  inputdir=${mergedir}/${contrast}/halfpipe
  mkdir -p ${mergedir}/${contrast}/ROI_extracted_z-values
  ROIdir=${mergedir}/${contrast}/ROI_extracted_z-values

  cd ${inputdir}
  
  for subj in $(ls -d sub-*); do
    echo ${subj}
    cd ${inputdir}/${subj}

    Zstatsfile=$(ls -1 *stat-z_statmap.nii.gz | head -1)

    #extract activation from ROIs and size of surviving personalized ROIs to a txt file
    if [ -f ${Zstatsfile} ]; then 
      if [ ! -f ${ROIdir}/${subj}_${contrast}.txt ]; then
        activations=$(fslstats -K ${atlasfile} ${inputdir}/${subj}/${Zstatsfile} -M)
        #only keep the 2nd column of the -V output (= volume in mm3) and round the number down to 0 decimals
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
  
  RBA_input=RBA_input_${contrast}_ROI.txt
  cd ${ROIdir}
  rm -f ${ROIdir}/${RBA_input}
  
  # Loop through all ROI activation files in the directory
  if [ ! -f ${ROIdir}/${RBA_input} ]; then
    for file in ${ROIdir}/sub-*.txt; do
      # Get the subject name from the file name
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
  > ${ROIdir}/../insufficient_volume_ROIs_${contrast}.txt

  # Create a temporary file to store the filtered output later
  temp_file=${ROIdir}/temp.txt

  # Add the column names to the output file
  echo "Subj,Sample,AGEGROUP,TASK,Dx,SEX,AGE,YBOCS,MED,AO,ROI,Y,Vol" >${temp_file}

  # Iterate over the ROIs in RBA_input and compare voxel numbers to original ROIs
  # Remove ROIs where at least 30% of voxels do not have signal
  for i in "${!personalized_ROI_values[@]}"; do
    while IFS=',' read -r Subj Sample AGEGROUP TASK Dx SEX AGE YBOCS MED AO ROI Y Vol; do
      # Get the volume from the corresponding key in roi_volumes
      echo $Subj
      roi_volume=${roi_volumes[$ROI]}

      # Calculate the threshold as 30% of the ROI volume
      threshold=$(awk "BEGIN {print $roi_volume * 0.3}")

      # Compare the subject's ROI volume with the 30% threshold
      if awk -v a=$Vol -v b=$threshold 'BEGIN { if (a < b) exit 0; exit 1 }'; then
        echo "${Subj}'s ${ROI} has a volume of ${Vol} mm3 which is less than 30% of ROI volume surviving" >> ${ROIdir}/../insufficient_volume_ROIs_${contrast}.txt
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
