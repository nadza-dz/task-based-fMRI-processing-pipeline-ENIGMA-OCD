#!/bin/bash

#SBATCH --job-name=RBA
#SBATCH --mem=4G
#SBATCH --partition=luna-cpu-long
#SBATCH --qos=anw-cpu-big
#SBATCH --cpus-per-task=32
#SBATCH --time=07-0:00:00

### N.Dzinalija VUmc 2023
### After 7_create_RBA_input_models.R has run, the resulting input RBA .txt files for each contrast
### and model are fed to this script through the 8-1b_submit_sbatch_RBA_ROI.sh 

# can run with 4 threads per chain
export APPTAINER_BIND="/data/anw/anw-work,/scratch"

contrast=${1}
model=${2}
group=${3}

RBA_dir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/RBA/ROI
RBA_input=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/${contrast}/RBA_input_${contrast}_ROI_${model}_${group}.txt

cd ${RBA_dir}
mkdir -p ${contrast}
cd ${contrast}
mkdir -p ${model}
cd ${model}
mkdir -p ${group}
cd ${group}

if [ ${model} == "BASE" ]; then
  covariatesC=\"Sample,Dx,SEX\"
  covariatesQ=\"AGE\"
  standardize=\"AGE\"
  statmodel=\"1+Sample+Dx+SEX+AGE\"
  EofI=\"Intercept,Dx\"
elif [ ${model} == "YBOCS" ]; then
  covariatesC=\"Sample,Dx,SEX\"
  covariatesQ=\"AGE,YBOCS\"
  standardize=\"AGE,YBOCS\"
  statmodel=\"1+Sample+YBOCS+SEX+AGE\"
  EofI=\"YBOCS\"
elif [ ${model} == "AO" ]; then
  covariatesC=\"Sample,AO,SEX\"
  covariatesQ=\"AGE\"
  standardize=\"AGE\"
  statmodel=\"1+Sample+AO+SEX+AGE\"
  EofI=\"AO\"
elif [ ${model} == "MED" ]; then
  covariatesC=\"Sample,MED,SEX\"
  covariatesQ=\"AGE\"
  standardize=\"AGE\"
  statmodel=\"1+Sample+MED+SEX+AGE\"
  EofI=\"MED\"
else
  echo "Invalid model input. Supported values are 'BASE', 'YBOCS', 'MED', and 'AO'."
fi

eval "apptainer run /scratch/anw/share-np/AFNIr RBA \
-prefix ${contrast}_${model}_${group} \
-chains 8 \
-iterations 4000 \
-dataTable ${RBA_input} \
-cVars ${covariatesC} \
-qVars ${covariatesQ} \
-stdz ${standardize} \
-scale 10 \
-distROI 'student' \
-model ${statmodel} \
-EOI ${EofI} \
-ridgePlot 40 30  \
-WCP 4 \
-PDP 4 3 \
-MD \
-verb 1"
