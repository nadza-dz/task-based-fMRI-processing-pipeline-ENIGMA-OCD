# Task-based fMRI mega-analyses in ENIGMA-OCD Working Group

This manual guides you through completing group-level analyses on individual participant task fMRI data. It was designed as a processing pipeline within the [ENIGMA-OCD consortium](https://enigma.ini.usc.edu/ongoing/enigma-ocd-working-group/). The principles of the consortium are that no raw data is shared, and that only processed and de-identified clinical and brain imaging data are shared with the lead site who carries out analyses. Therfore, this guide takes you through group-level analyses on already-processed first-level contrast maps using custom scripts and Bayesian multilevel models for regional and whole-brain analysis.

## Preprocessing

All raw data for the task-based fMRI analyses in ENIGMA-OCD has been processed using [HALFpipe](https://github.com/HALFpipe/HALFpipe) (Waller et al., 2022), an open-source containerized processing pipeline that was used for pre-processing and first-level feature extraction. The manual and acoompanying video tutorial explain how to process raw task data using HALFpipe for the ENIGMA-OCD task-based analyses.

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

The analyses were intended for the three cognitive domains of the task-based analyses in ENIGMA-OCD: emotional (negative) valence, inhibitory control, and executive function. Available task data across the ENIGMA-OCD consortium was categorized into one of these three domains, each of which is subserved by a partly distinct cogntivive circuit (fronto-limbic, ventral cognitive, and dorsal cognitive). The scripts available here were designed to be compatible with the Amsterdam University Medical Center's Luna server cluster. On the Luna server, all scripts can be found in `/data/anw/anw-gold/NP/projects/data_ENIGMA-OCD/ENIGMA-TASK/scripts/tb-mega-pipeline`. 

<p align="center">
  <img src="tb-fMRI-domains.png" alt="Cognitive domains" width="700"/><br/>
  <em>Cognitive domains investigated in task fMRI analyses</em>
</p>


### Preparation

Some preparation is needed before scripts can be run. Because each site used their own labels for participant IDs, task names, session and run names, etc, it is necessary to standardize everything to allow it to be cobmined at the group-level analysis stage. This requires preparing some documents first:

1.	Assign 3-digit sample codes to each sample, and a new 6-digit identifier to each participant. Convert this to a key-value dictionary with two columns: the old Subj ID and the new Subj ID. Save as Dictonary_SUB_ID.csv file.
   
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

<br><br>

2.	By checking each site's HALFpipe `/derivatives/halfpipe` folder, make a mega-analytic dictionary that inventories the labels that were used at that site for first-level features including: 1) sample, 2) site, 3) site code (the one you assigned in step #2 above), 3) task, 4) the various contrasts created at the first level, and 5) the various confound-removal strategies used in the first-level analyses (in this case: ICA-AROMA, motion-correction with 6 rigid-body motion parameters, and no correction). Save as Mega_analysis_dictionary.csv.
   
| Sample              | Site           | Code | Task | Contrast1_EMOgtNEUT | Contrast2_OCDgtNEUT | Contrast3_FEARgtNEUT | Contrast4__OCDgtFEAR | ICAAROMA | MOTIONCORR | NOCORR |
|:--------------------|:---------------|:-----|:-----|:-------------------|:-------------------|:--------------------|:-------------|:---------|:-----------|:-------|
| VUmc_ARRIBA_TIPICCO | van_den_Heuvel | 822  | SPT  | OCDFEARGtSCRAMBLED | OCDGtSCRAMBLED     | FEARGtSCRAMBLED     | OCDGtFEAR   | ICAAROMA | MOTIONCORR | NOCORR |
| VUmc_VENI           | van_den_Heuvel | 916  | ERT  | OCDFEARGtNEUT      | OCDGtNEUT          | FEARGtNEUT          | OCDGtFEAR   | ICAAROMA | MOTIONCORR | NOCORR |

<br><br>

3.	Organize HALFpipe outputs by creating one main directory containing a folder for each site. Inside each site folder, create one directory per sample and place the sample's HALFpipe folder into it

4.	Use `1_convert_site_files_to_codes.sh` script to create a cleaned and compiled version of all HALFpipe output. This will create a new `/merged` directory containing compiled files for each contrast of interest. These files aggregate all the data needed for group-level analyses, per participant. Additionally, the script assigns new participant IDs based on the files created above, and renames all files to ensure consistent naming and directory structure.





9.	Use 2_exclude_failed_QC_subs.sh to exclude subjects/runs which failed QC based on failed_QC.txt (same for both contrasts) that was prepared first in Excluded_data.xlsx 

10.	For samples that had multiple runs/sessions, run 3_fsl_glm_to_aggregate_sessions_runs.sh script

<p align="center">
  <img src="mega-analysis-methods.jpg" alt="Processing pipeline" width="1000"/><br/>
  <em>Processing pipeline in task-based fMRI mega-analyses</em>
</p>



## Publications using this pipeline

Dzinalija, N., Vriend, C., Waller, L., Simpson, H. B., Ivanov, I., Agarwal, S. M., Alonso, P., Backhausen, L. L., Balachander, S., Broekhuizen, A., Castelo-Branco, M., Costa, A. D., Cui, H., Denys, D., Duarte, I. C., Eng, G. K., Erk, S., Fitzsimmons, S. M. D. D., Ipser, J., Jaspers-Fayer, F., … van den Heuvel, O. A. (2024). Negative valence in Obsessive-Compulsive Disorder: A worldwide mega-analysis of task-based functional neuroimaging data of the ENIGMA-OCD consortium. Biological psychiatry, S0006-3223(24)01819-5. 

-Exec paper OSF link
-Inhib paper OSF link

## References

Chen, G., Xiao, Y., Taylor, P. A., Rajendra, J. K., Riggins, T., Geng, F., Redcay, E., & Cox, R. W. (2019). Handling Multiplicity in Neuroimaging Through Bayesian Lenses with Multilevel Modeling. Neuroinformatics, 17(4), 515-545.

van den Heuvel, O. A., Boedhoe, P., Bertolin, S., Bruin, W. B., Francks, C., Ivanov, I., Jahanshad, N., Kong, X. Z., Kwon, J. S., O'Neill, J., Paus, T., Patel, Y., Piras, F., Schmaal, L., Soriano-Mas, C., Spalletta, G., van Wingen, G. A., Yun, J. Y., Vriend, C., Simpson, H. B., … ENIGMA-OCD working group (2022). An overview of the first 5 years of the ENIGMA obsessive-compulsive disorder working group: The power of worldwide collaboration. Human Brain Mapping, 43(1), 23–36. 

Waller, L., Erk, S., Pozzi, E., Toenders, Y. J., Haswell, C. C., Büttner, M., Thompson, P. M., Schmaal, L., Morey, R. A., Walter, H., & Veer, I. M. (2022). ENIGMA HALFpipe: Interactive, reproducible, and efficient analysis for resting-state and task-based fMRI data. Human Brain Mapping, 43(9), 2727– 2742.
-Chen paper

