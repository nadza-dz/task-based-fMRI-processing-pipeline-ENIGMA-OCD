#!/bin/bash

### N.Dzinalija VUmc 2023
### After 7_create_RBA_input_models.R has run, the 8-2a_syntax_RBA_ROI_jackknife.sh script is run 
### for each model of PLANNING contrast, leaving one site out each time using this script.

scriptdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/scripts/tb_mega_pipeline/

for contrast in INHIBITION; do

    contrastdir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/${contrast}
    mkdir -p ${contrastdir}/leave_one_site_out

    for model in BASE YBOCS AO MED; do 
    
        mkdir -p ${contrastdir}/leave_one_site_out/${model}

        #for group in ADULT PED; do
        for group in ADULT; do

            mkdir -p ${contrastdir}/leave_one_site_out/${model}/${group}
            input=${contrastdir}/RBA_input_${contrast}_ROI_${model}_${group}.txt
            samples=$(tail -n +2 "${input}" | awk '{print $2}' | sed 's/"//g' | sort | uniq) # assumes 'sample' is 2nd column of input file

            for sample in ${samples}; do

                if grep -q "${sample}" ${input}; then

                    if [ ! -f ${contrastdir}/leave_one_site_out/${model}/${group}/RBA_input_${contrast}_ROI_${model}_${group}_leave_out_${sample}.txt ]; then
                        grep -v "${sample}" ${input} > ${contrastdir}/leave_one_site_out/${model}/${group}/RBA_input_${contrast}_ROI_${model}_${group}_leave_out_${sample}.txt
                        echo "Created input file for ${contrast}'s model ${model} for ${group} leaving out ${sample}"
                    fi

                    sbatch --output RBA_${contrast}_${model}_${group}_leave_out_${sample}.log ${scriptdir}/8-2a_syntax_RBA_ROI_jackknife.sh ${contrast} ${model} ${group} ${sample}
                fi

            done

        done

    done

done
