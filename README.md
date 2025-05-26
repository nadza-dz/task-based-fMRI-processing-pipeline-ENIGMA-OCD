# Task-based fMRI mega-analyses in ENIGMA-OCD Working Group

This manual guides you through completing group-level analyses on individual participant task fMRI data. It was designed as a processing pipeline within the [ENIGMA-OCD consortium](https://enigma.ini.usc.edu/ongoing/enigma-ocd-working-group/). The principles of the consortium are that no raw data is shared, and that only processed and de-identified clinical and brain imaging data are shared with the lead site who carries out analyses. Therfore, this guide takes you through group-level analyses on already-processed first-level contrast maps using custom scripts and Bayesian multilevel models for regional and whole-brain analysis.

## Preprocessing

All raw data for the task-based fMRI analyses in ENIGMA-OCD has been processed using [HALFpipe](https://github.com/HALFpipe/HALFpipe) (Waller et al., 2022), an open-source containerized processing pipeline designed within the ENIGMA consortium. HALFpipe was used for pre-processing and first-level feature extraction, and was run in an identical way across all sites to ensure harmonization of data (pre)processing. The manual and acoompanying video tutorial explain how to process raw task data using HALFpipe for the ENIGMA-OCD task-based analyses.

<table align="center">
  <tr>
    <td align="center">
      <a href="https://docs.google.com/document/d/1kQ0o0olXsk6lbkQMNW7pcSofKZvyctM/edit?usp=sharing&ouid=117298130236953584298&rtpof=true&sd=true">
        <img src="halfpipe-manual-ENIGMA-OCD.JPG" alt="Manual for HALFpipe preprocessing" style="max-width: 200px;">
      </a><br />
      <em>Manual for HALFpipe preprocessing:</em><br />
      <a href="https://docs.google.com/document/d/1kQ0o0olXsk6lbkQMNW7pcSofKZvyctM/edit?usp=sharing&ouid=117298130236953584298&rtpof=true&sd=true">Open document</a>
    </td>
    <td align="center">
      <a href="https://www.youtube.com/watch?v=zruXn-JLE5c">
        <img src="halfpipe-tutorial-ENIGMA-OCD.JPG" alt="Tutorial video for HALFpipe preprocessing" style="max-width: 200px;">
      </a><br />
      <em>Tutorial video for HALFpipe preprocessing:</em><br />
      <a href="https://www.youtube.com/watch?v=zruXn-JLE5c">Watch on YouTube</a>
    </td>
  </tr>
</table>

## Analyses

The analyses were intended for the three cognitive domains of the task-based analyses in ENIGMA-OCD: emotional (negative) valence, inhibitory control, and executive function. Available task data across the ENIGMA-OCD consortium was categorized into one of these three domains, each of which is subserved by a partly distinct cogntivive circuit (fronto-limbic, ventral cognitive, and dorsal cognitive). The scripts available here were designed to be compatible with the Amsterdam University Medical Center's Luna server cluster. On the Luna server, all scripts can be found in `/data/anw/anw-work/NP/projects/data_ENIGMA-OCD/ENIGMA-TASK/scripts/tb-mega-pipeline`. 

<p align="center">
  <img src="tb-fMRI-domains.png" alt="Cognitive domains" width="600"/><br/>
  <em>Cognitive domains investigated in task fMRI analyses</em>
</p>

<br><br>

In the figure below the processing pipeline is depicted for one of the domains - negative emotional valence. Using the manuals linked above, the steps of `Harmonzied processing` and `First-level contrast` extraction have already taken place. This manual will explain how to use the available scripts to execute `Mega-analysis`, investigating both case-control effects and the effects of clinical characteristics of OCD, such as the age of OCD onset, medication status, and symptom severity. Region of interest (ROI) analyses in the relevant neural circuit for each domain are conducted at the group-level, as well as whole-brain analyses via two separate approaches (not pictured). We refer to these analyses as mega-analyses because we use individual-participant data when combining datasets of multiple samples, which is a different than the approach meta-analyses typically take. Meta-analyses usually rely on summary statistics at the sample level, aggregating data across samples, but not across individual participants. A huge advantage of our mega-analytic approach is that we are able to investigate the effects of participant-level variables, such as medication status or symptom severity, on brain activity in a way that meta-analyses cannot.

<p align="center">
  <img src="mega-analysis-methods.jpg" alt="Processing pipeline" width="1000"/><br/>
  <em>Processing pipeline in task-based fMRI mega-analyses</em>
</p>


### Preparation

Some preparation is needed before scripts can be run. Because each site used their own labels for participant IDs, task names, session and run names, etc, it is necessary to standardize everything to allow it to be cobmined at the group-level analysis stage. This requires preparing some documents first:

1.	Assign 3-digit sample codes to each sample, and a new 6-digit identifier to each participant. Convert this to a key-value dictionary with two columns: the old Subj ID and the new Subj ID. Save as `Dictonary_SUB_ID.csv` file.
   
<table align="center">
  <thead>
    <tr>
      <th align="left">Original Subject ID</th>
      <th align="left">New Subject ID</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>sub-MRI201905101BART002</td><td>sub-550002</td></tr>
    <tr><td>sub-MRI201905211BART003</td><td>sub-550003</td></tr>
    <tr><td>sub-MRI201905291BART005</td><td>sub-550005</td></tr>
    <tr><td>sub-MRI201906031BART006</td><td>sub-550006</td></tr>
    <tr><td>sub-MRI201906051BART007</td><td>sub-550007</td></tr>
  </tbody>
</table>
<p align="center"><em>Dictionary_SUB_ID.csv</em></p>

<br><br>

2. Compile a covariate file `RBA_input_demographics_only.csv` of all relevant clinical and demographic data per subject. In these analyes this includes, in order of columns: 1) Subject ID, 2) Sample ID, 3) Task name, 4) Diagnosis (OCD/HC), 5) Sex, 6) Age, 7) Y-BOCS symptom severity score, 8) Medication status, and 9) Age of OCD onset.
   
| Subj       | Sample   | Task   | Diagnosis  | Sex | Age | Y-BOCS | Medication Status | Age of Onset    |
|------------|----------|--------|-----|-----|-----|-------|-----|-------|
| sub-550002 | BRAGA_ER |  Symtpom provocation task | OCD | m   | 21  | 19    | Med | Child |
| sub-550003 | BRAGA_ER |  Symtpom provocation task | OCD | m   | 18  | 28    | Med | Child |
| sub-550005 | BRAGA_ER |  Symtpom provocation task | OCD | f   | 55  | 28    | Med | Adult |
<p align="center"><em>RBA_input_demographics_only.csv</em></p>

<br><br>

3.	By checking each site's HALFpipe `/derivatives/halfpipe` folder, make a mega-analytic dictionary that inventories the labels that were used at that site for first-level features including: 1) sample, 2) site, 3) site code (the one you assigned in step #2 above), 3) task, 4) the various contrasts created at the first level, and 5) the various confound-removal strategies used in the first-level analyses (in our case: 1) ICA-AROMA, 2) motion-correction with 6 rigid-body motion parameters, and 3) no correction). Save as `Mega_analysis_dictionary.csv`.
   
| Sample              | Site           | Code | Task | Contrast1_EMOgtNEUT | Contrast2_OCDgtNEUT | Contrast3_FEARgtNEUT | Contrast4__OCDgtFEAR | ICAAROMA | MOTIONCORR | NOCORR |
|:--------------------|:---------------|:-----|:-----|:-------------------|:-------------------|:--------------------|:-------------|:---------|:-----------|:-------|
| VUmc_ARRIBA_TIPICCO | van_den_Heuvel | 822  | SPT  | OCDFEARGtSCRAMBLED | OCDGtSCRAMBLED     | FEARGtSCRAMBLED     | OCDGtFEAR   | ICAAROMA | MOTIONCORR | NOCORR |
| VUmc_VENI           | van_den_Heuvel | 916  | ERT  | OCDFEARGtNEUT      | OCDGtNEUT          | FEARGtNEUT          | OCDGtFEAR   | ICAAROMA | MOTIONCORR | NOCORR |
<p align="center"><em>Mega_analysis_dictionary.csv</em></p>

<br><br>

4.	Organize HALFpipe outputs by creating one main directory containing a folder for each site. Inside each site folder, create one directory per sample and place the sample's HALFpipe folder into it.

5.	Perform quality control (QC) using the [HALFpipe QC manual](https://drive.google.com/file/d/1TMg9MRvBwZO8HB1UJmH0gm4tYaBVnvcQ/view) and create a `failed_QC.txt` that lists all participants who failed QC. If a participant fails QC for one run but not another, the data from the remaining run can still be used - in this case mention which run was excluded in the `failed_QC.txt` file. If all runs should be excluded, leave the `Runs` column empty and the participant will be entirely excluded from further analyses.

<table align="center">
  <thead>
    <tr>
      <th align="left">Subject ID</th>
      <th align="left">Runs</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>sub-822011</td><td></td></tr>
    <tr><td>sub-916079</td><td>2</td></tr>
    <tr><td>sub-916081</td><td>1</td></tr>
  </tbody>
</table>
<p align="center"><em>failed_QC.txt</em></p>

<br><br>


6.	Use `1_convert_site_files_to_codes.sh` script to create a cleaned and compiled version of all HALFpipe output. This will create a new `/merged` directory containing compiled files for each contrast of interest. These files aggregate all the data needed for group-level analyses, per participant. Additionally, the script assigns new participant IDs based on the files created above, and renames all files to ensure consistent naming and directory structure.

7.	Use `2_exclude_failed_QC_subs.sh` script to exclude participants who failed QC based on `failed_QC.txt`
   
8.	Use `3_fsl_glm_to_aggregate_sessions_runs.sh` script to aggregate contrast maps across runs or sessions at the participant-level for samples that employed a task design with multiple runs or sessions. This step ensures that each participant contributes only one observation to the group-level analyses by averaging across all available runs or sessions with a simple intercept model.
   
<br><br>


### Region-Of-Interest analyses

For the circuit-level analyses, we have expectations about where activation will be found based on previous meta-analyses that were done either in healthy controls or in individuals with OCD on the task domains that we investigate here. We therefore first restrict analyses to these regions to investiggate the circuits of interest before we move to whole-brain analyses.

1. Create ROI nifti images. Subcortical ROIs are created with the [Melbourne subcortical atlas](https://github.com/yetianmed/subcortex)(Tian et al., 2020) which is in the same MNI2009c asymmetrical space as HALFpipe uses. Cortical ROIs are created as 5-mm spheres around coordinates identified in literature (Thorsen et al., 2018; Nitschke et al., 2017; Norman et al., 2019). However, the coordinates from these papers were originally not in the MNI2009c asymmetrical space but rather in older MNI version 6 space, and need to be converted first. Create a `ROI_MNI6_coordinates.txt` file in which each cortical ROI and its x, y, z coordinates in MNI v. 6 space are listed.
   
<table align="center">
  <thead>
    <tr>
      <th align="left">Region</th>
      <th align="left">X</th>
      <th align="left">Y</th>
      <th align="left">Z</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>LOC_l</td><td>-32</td><td>-90</td><td>-10</td></tr>
    <tr><td>LOC_r</td><td>32</td><td>-90</td><td>-10</td></tr>
    <tr><td>MTG_l</td><td>-58</td><td>-50</td><td>8</td></tr>
    <tr><td>MTG_r</td><td>58</td><td>-50</td><td>8</td></tr>
    <tr><td>vmPFC_l</td><td>-4</td><td>42</td><td>-18</td></tr>
    <tr><td>vmPFC_r</td><td>4</td><td>42</td><td>-18</td></tr>
    <tr><td>sgACC_l</td><td>-4</td><td>34</td><td>-8</td></tr>
    <tr><td>sgACC_r</td><td>4</td><td>34</td><td>-8</td></tr>
  </tbody>
</table>
<p align="center"><em>ROI_MNI6_coordinates.txt</em></p>
<br><br>

   
2. Use `4_make_spheres_MNI2009.sh` script to create nifti images of ROIs in MNI space based on the `ROI_MNI6_coordinates.txt` file.
   
    a) If there are overlapping regions across spheres:
   
    - Remove overlapping regions from spheres by multiplying spheres by hemisphere mask to get non-overlapping right/left spheres.
      ```bash
      fslmaths tpl-MNI152NLin2009cAsym_res-02_desc-brain_T1w.nii.gz -roi 0 48.5 0 -1 0 -1 0 -1 -bin leftHemisphere
      fslmaths tpl-MNI152NLin2009cAsym_res-02_desc-brain_T1w.nii.gz -roi 48.5 -1 0 -1 0 -1 0 -1 -bin rightHemisphere
      ```
   > 48.5 determined by taking half of dim 1 after running `fslinfo tpl-MNI152NLin2009cAsym_res-02_desc-brain_T1w.nii.gz`

    b) If there are multiple coordinates for a single region:

    - Cobmine regions with multiple coordinates into single image with both regions
      ```bash
      fslmaths FEF_r1.nii.gz -add FEF_r2.nii.gz FEF_r.nii.gz
      ```
      This gives both spheres the same value in the atlas file, so when extracted later the activation reflects the average of both spheres

3. Extract volumes of ROIs into `ROIs_volume.txt`. This will be used later for checking that there is sufficient signal in each ROI when extracting activation in the region.

```bash
for ROI in *.nii.gz; do
  echo "${ROI%.nii.gz}" $(fslstats ${ROI} -V >> ROIs_volume.txt
done
```
<table align="center">
  <thead>
    <tr>
      <th align="left">Region</th>
      <th align="left">Voxel Count</th>
      <th align="left">Volume (mm³)</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>amygdala_l</td><td>395</td><td>3160.000000</td></tr>
    <tr><td>amygdala_r</td><td>380</td><td>3040.000000</td></tr>
    <tr><td>LOC_l</td><td>81</td><td>648.000000</td></tr>
    <tr><td>LOC_r</td><td>81</td><td>648.000000</td></tr>
    <tr><td>MTG_l</td><td>81</td><td>648.000000</td></tr>
    <tr><td>MTG_r</td><td>81</td><td>648.000000</td></tr>
    <tr><td>putamen_l</td><td>919</td><td>7352.000000</td></tr>
    <tr><td>putamen_r</td><td>940</td><td>7520.000000</td></tr>
    <tr><td>sgACC_l</td><td>72</td><td>576.000000</td></tr>
    <tr><td>sgACC_r</td><td>72</td><td>576.000000</td></tr>
    <tr><td>vmPFC_l</td><td>72</td><td>576.000000</td></tr>
    <tr><td>vmPFC_r</td><td>72</td><td>576.000000</td></tr>
  </tbody>
</table>
<p align="center"><em>ROIs_volume.txt</em></p>

<br><br>

> For visualization of ROIs on a glass brain, BrainNetViewer in Matlab is handy. Go to File > Load file > Surface file: BrainNetViewer\Data\SurfTemplateBrainMesh_ICBM152_smoothed.nv > Mapping file: 3D nifti file with all ROIs. Once loaded, go to Volume > Type selection > ROI drawing

4. Use `5_extract_activation_from_ROIs.sh` script to extract activation from ROIs.

### Whole-brain analyses

Two approaches are taken to whole-brain analyses here. Typically, when we speak of whole-brain analyses in fMRI we mean a voxel-wise analysis where a statistical model is fit to every voxel over the entire brain. However, I aimed to use Bayesian statistics for my analyses which involve many simultations over each unit of analysis, and doing this over every voxel in the brain would be too computationally expensive. Therefore a parcellated approach is taken, where activation is averaged over regions of the functionally-defined [Schaefer cortical atlas](https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal) (Schaefer et al., 2018). This also has the advantage that it solves another problem of our dataset. Because our analyses include a large number of participants drawn from many different samples, the brain coverage across participants can vary substantially. By averaging activation over larger cortical regions, we can retain more participants in the analysis—even if the exact voxels imaged vary slightly between them.

1. Use `6_extract_activation_from_Schaefer_Melbourne_parcels.sh` script to extract activation from Schaefer cortical atlas parcels and Melbourne subcortical atlas regions. 

### Running models

For these analyses I have chosen to run a Bayesian equivalent of a multilevel model to investigate activation differences in cases and control using the [Bayesian Region-Based Analysis (RBA) toolbox](https://afni.nimh.nih.gov/pub/dist/doc/program_help/RBA.html) (Chen et al., 2019). Bayesian statistics offers several advantages over classical frequentist methods, some of which are particularly relevant for neuroimaging data like ours.First, unlike frequentist inference, which quantifies the probability of observing the data given a null hypothesis, Bayesian multilevel analysis allows us to estimate the probability of a hypothesis given the observed data. This means we can incorporate prior knowledge (even if limited) and combine it with the observed brain activations to compute the posterior probability that activations differ between individuals with OCD and healthy controls. This approach enables us to directly assess the credibility of our hypotheses. Second, rather than applying separate general linear models to each ROI, RBA jointly models all ROIs within a single hierarchical model. This approach accounts for the non-independence of brain regions within individuals, recognizing that activation patterns across regions in the same brain are more similar than those across different individuals. Third, because the multilevel model captures the inherent dependencies among brain regions within an individual, and individuals within a sample, it addresses the multiple comparisons problem directly. There is no inflation of familywise error rates, and therefore no need for post hoc correction for multiple testing. Finally, by using Bayesian statistics we promote full and transparent reporting of the results and eliminate pass/fail dichotomization based on (arbitrary) p-values. A full guide to understanding, running, and interpreting these RBA analyses, written by Aniek Broekhuizen and myself, can be found [here](https://docs.google.com/document/d/1kQ0o0olXsk6lbkQMNW7pcSoqfKZvyctM/edit?usp=sharing&ouid=117298130236953584298&rtpof=true&sd=true).

1. Create input files for Bayesian ROI analyses. These input files consist of extracted activation from ROIs (done above) as well as demographic and clinical variables that should be in the `RBA_input_demographics_only.csv` file above. Individual input files for each model are created by the `7_create_RBA_input_models.R` script.

2.

## Missing data

To help identify missing data the scripts output files that help identify the reasons for which participants were excluded from analyses, or which data is missing. There are four types of excluded participants/data:
1. Participants excluded due to failing quality control checks - visible in `failed_QC.txt`
2. Participants excluded due to too much motion (framewise displacement >1.0) - visible in `failed_FD1.0.txt` 
3. Participants for who a portion of the first-level processing pipeline failed to run, for example the ICA-AROMA confound removal - visible in `failed_ICA.txt`
4. Participants who have missing data for some brain regions due to having <30% of the ROI/parcel volume in the field of view  - visible in `insufficient_volume_ROIs.txt` for defined ROIs and `insufficient_volume_parcels.txt` for Schaefer/Melbourne parcellated atlas regions

All these files will be written to the `/merged` directory's contrast-of-interest folders (except `failed_QC.txt` which is made in Preparation step #5 above), making it easy to inspect output.


## Publications using this pipeline

Dzinalija, N., Vriend, C., ENIGMA-OCD Consortium, … , Veer, I., van den Heuvel, O. A. (2024). Negative valence in Obsessive-Compulsive Disorder: A worldwide mega-analysis of task-based functional neuroimaging data of the ENIGMA-OCD consortium. Biological psychiatry, S0006-3223(24)01819-5. 

Dzinalija, N., Veer, I., ENIGMA-OCD Consortium, … , van den Heuvel, O. A., Vriend, C. (2025). Executive control in Obsessive-Compulsive Disorder: A worldwide mega-analysis of task-based functional neuroimaging data of the ENIGMA-OCD consortium. https://osf.io/ebtpk

Dzinalija, N.,  van den Heuvel, O. A., ENIGMA-OCD Consortium, … , Vriend, C., Veer, I. (2025). Inhibitory control in OCD: A mega-analysis of task-based fMRI data of the ENIGMA-OCD consortium. https://osf.io/mhq8t


## References

Chen, G., Xiao, Y., Taylor, P. A., Rajendra, J. K., Riggins, T., Geng, F., Redcay, E., & Cox, R. W. (2019). Handling Multiplicity in Neuroimaging Through Bayesian Lenses with Multilevel Modeling. Neuroinformatics, 17(4), 515-545.

Schaefer A, Kong R, Gordon ME, Laumann OT, Zuo X-N, Holmes JA, et al. Local-Global Parcellation of the Human Cerebral Cortex from Intrinsic Functional Connectivity MRI. Cerebral Cortex. 2018;28(9):3095-114.

Tian Y, Margulies SD, Breakspear M, Zalesky A. Topographic organization of the human subcortex unveiled with functional connectivity gradients. Nature Neuroscience. 2020;23(11):1421-32.

van den Heuvel, O. A., Boedhoe, P., Bertolin, S., Bruin, W. B., Francks, C., Ivanov, I., Jahanshad, N., Kong, X. Z., Kwon, J. S., O'Neill, J., Paus, T., Patel, Y., Piras, F., Schmaal, L., Soriano-Mas, C., Spalletta, G., van Wingen, G. A., Yun, J. Y., Vriend, C., Simpson, H. B., … ENIGMA-OCD working group (2022). An overview of the first 5 years of the ENIGMA obsessive-compulsive disorder working group: The power of worldwide collaboration. Human Brain Mapping, 43(1), 23–36. 

Waller, L., Erk, S., Pozzi, E., Toenders, Y. J., Haswell, C. C., Büttner, M., Thompson, P. M., Schmaal, L., Morey, R. A., Walter, H., & Veer, I. M. (2022). ENIGMA HALFpipe: Interactive, reproducible, and efficient analysis for resting-state and task-based fMRI data. Human Brain Mapping, 43(9), 2727– 2742.


