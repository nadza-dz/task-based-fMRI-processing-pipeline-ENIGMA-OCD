#!/bin/bash
# N.Dzinalija VUmc 2023

### Make points in MNI6 space using coordinates published in Thorsen et al., Nitschke et al., or Norman et al.
### then convert to MNI2009 space and make sphere around coordinate point.
### Extract activation from both spheres and anatomical ROIs using 5_extract_activation_from_ROIs.sh script.

module load fsl/6.0.7.6
module load ANTs/2.4.1

MNI6temp=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
MNI2009temp=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/MNI152NLin2009/MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_T1w.nii.gz

for contrast in INHIBITION ERROR; do
    roidir=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/ROIs/${contrast}
    roilist=/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/ROIs/${contrast}/ROI_MNI6_coordinates.txt
    dos2unix ${roilist}

    # read in list of ROI coordinates
    for roi in `cat ${roilist} | awk '{ print $1 }' `; do

        echo "ROI is ${roi}"

        MNI6_x=$(cat ${roilist} | grep ${roi} |  awk '{ print $2 }')
        MNI6_y=$(cat ${roilist} | grep ${roi} |  awk '{ print $3 }')
        MNI6_z=$(cat ${roilist} | grep ${roi} |  awk '{ print $4 }')

        # find coordinate in voxel space
        VX_coord=$(echo $MNI6_x $MNI6_y $MNI6_z | std2imgcoord -img ${MNI6temp} -std ${MNI6temp} -vox -)
 
        VX_x=$(echo ${VX_coord} | awk '{ print $1 }')
        VX_y=$(echo ${VX_coord} | awk '{ print $2 }')
        VX_z=$(echo ${VX_coord} | awk '{ print $3 }')


        # make point at MNI coordinate in MNI6 space 
        mkdir -p ${roidir}/MNI6
        fslmaths ${MNI6temp} -mul 0 -add 1 -roi $VX_x 1 $VX_y 1 $VX_z 1 0 1 ${roidir}/MNI6/${roi}_MNI6_main -odt float


        # warp to MNI2009c space 
        mkdir -p ${roidir}/MNI2009
        antsApplyTransforms -i ${roidir}/MNI6/${roi}_MNI6_main.nii.gz \
        -r ${MNI2009temp} \
        -o ${roidir}/MNI2009/${roi}_MNI2009.nii.gz \
        -t /data/anw/anw-work/NP/projects/data_ENIGMA_OCD/MNI6_to_MNI2009/MNI_6thgen_2_MNI2009b.h5

        # find center of gravity of point in MNI2009c space (because it warps not to a point but to a square)
        CofG=$(fslstats ${roidir}/MNI2009/${roi}_MNI2009.nii.gz -C)
        read -r VX_x_new VX_y_new VX_z_new <<< $CofG
        rm ${roidir}/MNI2009/${roi}_MNI2009.nii.gz

        # make (single) point at MNI coordinate in MNI2009c space
        mkdir -p ${roidir}/MNI2009/MNI_coordinates/
        fslmaths ${MNI2009temp} -mul 0 -add 1 -roi $VX_x_new 1 $VX_y_new 1 $VX_z_new 1 0 1 ${roidir}/MNI2009/MNI_coordinates/${roi}_MNI2009_main -odt float

        # create 5 mm sphere around coordinate in MNI2009 space
        mkdir -p ${roidir}/MNI2009/original_spheres
        fslmaths ${roidir}/MNI2009/MNI_coordinates/${roi}_MNI2009_main.nii.gz -kernel sphere 5 -fmean -bin ${roidir}/MNI2009/original_spheres/${roi}_MNI2009_sphere5.nii.gz
    done
    
    # create 3D atlas of all ROIs 
    mkdir -p ${roidir}/All_combined
    cd ${roidir}/MNI2009/original_spheres
    files=($(ls *.nii* | sort))
    numROIs="${#files[@]}"
    atlasfile=${roidir}/All_combined/3D_atlas_${numROIs}ROIs.nii.gz 

    # Create an empty 3D image to start with 
    fslmaths ${files[0]} -mul 0 ${atlasfile} 
    >${roidir}/ROIs_order.txt   
    >${roidir}/ROIs_volume.txt
    # Loop through the list and assign each file a unique index 
    for i in "${!files[@]}"; do 
        file=${files[$i]} 
        cp $file ${roidir}/MNI2009/${file%_MNI2009_sphere5.nii.gz}.nii.gz

        echo ${file%_MNI2009_sphere5.nii.gz}>>${roidir}/ROIs_order.txt
        echo ${file%_MNI2009_sphere5.nii.gz} $(fslstats ${file} -V)>>${roidir}/ROIs_volume.txt

        index=$((i + 1)) 
        temp_file="temp_${index}.nii.gz"
        # Multiply the file by its unique index 
        fslmaths $file -mul $index $temp_file 
        # Add the resulting image to the merged image 
        fslmaths ${atlasfile} -add $temp_file ${atlasfile} 
        # Remove the temporary file 
        rm $temp_file 

        # Add original binary mask to 4D list
        volumes_for_4d+=($file)
    done

    # create 4D concatenated file of all ROIs (masks)
    #fslmerge -t ${roidir}/All_combined/4D_concatenated_${numROIs}ROIs.nii.gz "${volumes_for_4d[@]}"

done

