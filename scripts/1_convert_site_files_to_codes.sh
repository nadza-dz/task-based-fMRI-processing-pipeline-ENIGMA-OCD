#!/bin/bash
# N.Dzinalija VUmc 2022

# In order to harmonize processing across sites when merging the derivatives/halpipe folder
# we assign a site code and rename all subject folders and subject output files by appending code.

# For inhibitory processing domain the sites, samples, and unique identifier codes are:

# Sample		Site			Sample_ID	Task_name      	Contrast_INHIBITON_name  	Contrast_ERROR_name 		Feature_ICA_name	Feature_MOCO_name	Feature_NOCO_name
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# AMC_TBM		van_Wingen		837		SST		STOPCORRGtGOCORR		STOPERRGtSTOPCORR		ICAAROMA		MOTIONCORR		NOCORR
# AMC_BASCULE		Huyser			212		FLANKER		inhibition			error				FLANKERICAAROMA		FLANKERMOTIONCORR	FLANKERNOCORR
# BARCELONA		Fullana			727		stopsignal	contrast1			contrast2			ICAAROMA		MOTIONCORR		NOCORR
# BERGEN_B4DT		Thorsen			244		SST		inhibition			error				ICAAROMA		SSTMOTIONCORR		SSTNOCORR
# COIMBRA		Castelo-Branco		252		SST		SuccessfulStopGtCorrectGo	FailedStopGtSuccessfulStop	ICAAROMA		MOTIONCORR		NOCORR
# COMPULS		Buitelaar		302		STOP		Inhibition			Error							MOTIONCORR		NOCORR
# HUB_3T		Kathmann		974		FLANKER		inhibition			error				FLANKERICAAROMA		FLANKERMOTIONCORR	FLANKERNOCORR
# IDIBELL_15T		Menchon_Soriano-Mas	656		STOP		INHIBITION			ErrorSTOP			ICAAROMA		MOTIONCORR		NOCORR
# IDIBELL_3T		Menchon_Soriano-Mas	565		STOP		Inhibition			ErrorSTOP			ICAAROMA		MOTIONCORRSTOP		NOCORRSTOP
# MUC_TUM		Koch			187		SST		Inhibition			F				ICAAROMASST		MOTIONCORRSST		NOCORRSST
# NIMHANS_GONOGO	Reddy			833		GNG		Inhibition							ICAAROMA		MOTIONCORR		NOCORR
# SEOUL_SST		Kwon			523		SST		Inhibition			Error				ICAAROMA		MOTIONCORR		NOCORR
# SEQ_1_NKI		Stern			904		UFA		HoldBlinkGtNormalBlink						ICAAROMA		MOTIONCORR		NOCORR
# UZH_OCD		Walitza_Brem		452		flanker		contrast3_conflict		contrast5Error			ICAAROMA		MOTIONCORR		NOCORR
# VUmc_TIPICCO		van_den_Heuvel		822		SST		inhibition			error				SSTICAAROMA		SSTMOTIONCORR		SSTNOCORR
# VUmc_VENI		van_den_Heuvel		916		STOP		inhibition			error				SSTICAAROMA		SSTMOTIONCORR		SSTNOCORR
# ABCD_SST		ABCD			100		SST		Inhibition			Error							MOTIONCORR		NOCORR						
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#######################################################################################################################################
### Paths ####

HALFPIPEdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Executive_domain/HALFpipe_output
MERGEDdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/derivatives/halfpipe
SUBidKEY=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/Dictionary_SUB_ID.txt
MEGAdict=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/Dictionary_mega_analysis.txt

INHIBITION=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/INHIBITION/halfpipe
ERROR=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/ERROR/halfpipe

### Initialize empty files for storing failed subjects
> ${INHIBITION}/../failed_MOCO.txt
> ${ERROR}/../failed_MOCO.txt

### Load Subject ID dictionary (Old, new names key-value pairs)
# Read the text file into an array
dos2unix ${SUBidKEY}

declare -A codes
while IFS=, read name title; do
	codes[$name]=$title
	echo ${codes[$name]}
done <${SUBidKEY}

### Load all info relating to site (code, task, contrast, feature) into dictionary
dos2unix ${MEGAdict}
declare -A dictionary
while IFS=$',' read -r sample site code task contrast_INHIBITION contrast_ERROR  featureICA featureMOCO featureNO; do
	if [[ $sample != "sample" ]]; then
		# Create a string representation of the values for the current site
		values="${sample}:${site}:${code}:${task}:${contrast_INHIBITION}:${contrast_ERROR}:${featureICA}:${featureMOCO}:${featureNO}"

		# Add the string of values to the dictionary using the site as the key
		dictionary["$sample"]=$values
		echo ${dictionary["$sample"]}
	fi
done <${MEGAdict}

### Convert each subject to new subject ID, and all files in derivatives folder
## Then identify contrasts of interest and move files needed for mega-analysis to their own folders
readarray -t samples < <(awk -F',' 'NR>1 {print $1}' "$MEGAdict")
for sample in "${samples[@]}"; do
	sample_to_search=${sample}
	echo $sample
	values="${dictionary["$sample_to_search"]}"
	IFS=':' read -r sample site code task contrast_INHIBITION contrast_ERROR featureICA featureMOCO featureNO <<<"$values"

	cd ${HALFPIPEdir}/${site}/${sample}/derivatives/halfpipe

	ls -d sub-* >${HALFPIPEdir}/${site}/${sample}/subjdirs.txt

	for sub in $(cat ${HALFPIPEdir}/${site}/${sample}/subjdirs.txt); do
		SUBCODE=${codes["${sample}_${sub}"]}
		
		if [ ! -z "$SUBCODE" ]; then
			TASKdir=$(find ${HALFPIPEdir}/${site}/${sample}/derivatives/halfpipe/${sub} -type d -name "task-${task}")
			
			if [ -n "$TASKdir" ]; then
			
				if [ ! -d ${MERGEDdir}/${SUBCODE} ]; then
					echo "converting $sub using code $code to $SUBCODE"

					# move each subject folder into merged using symlinks rather than rsync (which creates copy of file)
					# Use find to locate all files in the source directory that come from the desired task 
					echo "$TASKdir" | while read task_dir; do
						# Locate all files in the found 'task-TOL' directory
						find ${task_dir} -type f | while read file; do
							# Determine the relative path of the file
							relative_path=${file#${HALFPIPEdir}/${site}/${sample}/derivatives/halfpipe/}

							# Create the target directory if it does not exist
							mkdir -p ${MERGEDdir}/$(dirname ${relative_path})

							# Create the symlink
							ln -s ${file} ${MERGEDdir}/${relative_path}
						done
					done

					# rename each file in subject folder if needed
					SUBpaths=$(find -L ${MERGEDdir}/${sub} -path "*/func/task-${task}" -type d)

					for SUBpath in $SUBpaths; do
						cd "$SUBpath"

						# prevent dotfiles from being included
						for i in *; do
							if [[ ! ${i} == ${SUBCODE}_* ]]; then
								filestring=${i#*_} # extract non-subID part of filename (everything after 1st underscore)
								mv "$i" "${SUBCODE}_${filestring}"
							fi
						done
					done

					# rename subject folder in derivatives/halfpipe if needed
					if [ ! -d ${MERGEDdir}/${SUBCODE} ]; then 
						mv ${MERGEDdir}/${sub} ${MERGEDdir}/${SUBCODE}
					fi
				else
					echo "$sub already copied over"
				fi
			fi
		fi
	done


	# CONTRASTS : move to new dir everything that is needed for mega-analysis

	for contrast in INHIBITION ERROR; do
		
		CONTRASTdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/${contrast}/halfpipe
		con_name="contrast_${contrast}"
		con_value=${!con_name}
		
		if [ ! -z "$con_value" ]; then		
		
			#check whether there are multiple "sub-contrasts" for this main contrast for this sample 
			#occurs in for ex TOL task depending on how many conditions a ppt had, so if they had only TOL1-3 correct but not 4-5, they may have a TOL123>counting while another participant may have TOL12345>counting
			IFS=' ' read -r -a contrast_array <<< "$con_value"
			num_contrasts=${#contrast_array[@]}
		
			cd ${MERGEDdir}
			
			
			for sub in sub-${code}*; do
				
				#check if the MOTIONCORR ran for this subject
				zstatmapExists=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}*taskcontrast-${con_value}*_stat-z_statmap.nii.gz" -print)
				if [ -n "$zstatmapExists" ]; then
					
					if [ "$num_contrasts" -eq 1 ]; then
						contrast_to_use=${con_value}
				
					elif [ "$num_contrasts" -gt 1 ]; then
						planningLower="${contrast_array[0]}"
						planningHigher="${contrast_array[1]}"
						
						#if 'higher' task load contrast exists for that subject (ordered by load in mega dictionary file), then use this one, otherwise use lower task load contrast
						zstatmapHigher=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}_taskcontrast-${planningHigher}_stat-z_statmap.nii.gz" -print)

						if  [ -n "$zstatmapHigher" ]; then
							contrast_to_use=${planningHigher}
						else
							contrast_to_use=${planningLower}
						fi
					
					fi
					
					zstatmaps=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}_taskcontrast-${contrast_to_use}_stat-z_statmap.nii.gz" -print)
					effectmaps=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}_taskcontrast-${contrast_to_use}_stat-effect_statmap.nii.gz" -print)
					effectjsons=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}_taskcontrast-${contrast_to_use}_stat-effect_statmap.json" -print)
					variancemaps=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}_taskcontrast-${contrast_to_use}_stat-variance_statmap.nii.gz" -print)
					masks=$(find -L ${MERGEDdir}/${sub} -path "*${sub}*task-${task}*feature-${featureMOCO}_taskcontrast-${contrast_to_use}_mask.nii.gz" -print)
					
					#extra check
					if  [ -z "$zstatmaps" ] || [ -z "$effectmaps" ] || [ -z "$effectjsons" ] || [ -z "$variancemaps" ] || [ -z "$masks" ]; then
						echo "ERROR! one of the files could not be found in ${MERGEDdir}/${sub}"
						echo "$sub" >> ${CONTRASTdir}/../failed_MOCO.txt
						#exit
					fi
							
					if [ ! -d ${CONTRASTdir}/${sub} ]; then
						mkdir ${CONTRASTdir}/${sub}
						echo "copying ${sub} files for ${contrast_to_use} to ${CONTRASTdir}"

						# Create symlinks for all found files
						for zstatmap in ${zstatmaps[@]}; do
							ln -s ${zstatmap} ${CONTRASTdir}/${sub}/$(basename ${zstatmap})
						done
						
						for effectmap in ${effectmaps[@]}; do
							ln -s ${effectmap} ${CONTRASTdir}/${sub}/$(basename ${effectmap})
						done
						
						for effectjson in ${effectjsons[@]}; do
							ln -s ${effectjson} ${CONTRASTdir}/${sub}/$(basename ${effectjson})
						done
						
						for variancemap in ${variancemaps[@]}; do
							ln -s ${variancemap} ${CONTRASTdir}/${sub}/$(basename ${variancemap})
						done
						
						for mask in ${masks[@]}; do
							ln -s ${mask} ${CONTRASTdir}/${sub}/$(basename ${mask})
						done
				
						#rsync -av ${zstatmap} ${effectmap} ${effectjson} ${variancemap} ${mask} ${CONTRASTdir}/${sub}
					fi
					
					unset zstatmap effectmap effectjson variancemap mask
				else
					echo "$sub" >> ${CONTRASTdir}/../failed_MOCO.txt
				fi
			done

		fi
		
	done
	
done


