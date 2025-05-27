## Voxel-wise whole-brain analyses: IBMMA-toolbox

A new method was developed within ENIGMA specifically for mega-analyses of multi-cohort datasets at a voxel level by Delin Sun in his [IBMMA toolbox](https://github.com/sundelinustc/IBMMA/tree/2024-10-21). It is called IBMMA (Image-Based Meta- & Mega-Analysis) precicely because it is designed to process whole-brain statistical map images and apply mass-univariate statistical models to diverse neuroimaging features, including voxel-based functional brain measures. Using IBMMA requires very little extra preparation after the above steps have been executed, and produces whole-brain voxel-wise group-level results that can be used to enrich the [parcellated whole-brain approach](README.md#whole-brain-analyses) above.

1.	Open a large interactive slurm session (I used 24 CPUs and 50GB RAM)

    ```bash
    salloc --job-name Interactive --cpus-per-task 24 --mem 50G --time 8:00:00 --partition luna-cpu-short --qos anw-cpu --x
    ```
  
2.	Download the entire [IBMMA github repository](https://github.com/sundelinustc/IBMMA/tree/2024-10-21) and unzip it in your `/scratch` directory
   
3.	Prepare `path_para.xlsx` file according to instructions in the file. See [path_para.xlsx](files/path_para.xlsx) for an example.
   
4. Prepare covariates file
   
    a. Covariate file must have first column `fID` with following structure: sample_subject
   
    - Since our sample directory is named `halfpipe` for each contrast of interest in each domain, this should be for example: `halfpipe_sub-157001`
     	  	
    b.	Covariate file should have no string variables, all string variables should be converted to numerical, including `sample`. If this has not been done in the covariate file itself, ensure the `predictors` sheet of the `path_para.xlsx` file contains a mapping of string variables to numeric values.

<table align="center">
  <thead>
    <tr>
      <th>fID</th><th>Subject</th><th>Sample</th><th>TASK</th><th>DX</th>
      <th>YBOCS</th><th>AGE</th><th>SEX</th><th>AO</th><th>MED</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>halfpipe_sub-157001</td><td>sub-157001</td><td>1</td><td>TOL</td><td>OCD</td><td>28</td><td>42</td><td>m</td><td>Adult</td><td>Unmed</td></tr>
    <tr><td>halfpipe_sub-157002</td><td>sub-157002</td><td>1</td><td>TOL</td><td>HC</td><td></td><td>39</td><td>m</td><td>HC</td><td>HC</td></tr>
    <tr><td>halfpipe_sub-157003</td><td>sub-157003</td><td>1</td><td>TOL</td><td>OCD</td><td>36</td><td>36</td><td>f</td><td>Adult</td><td>Med</td></tr>
    <tr>
      <td colspan="10" align="center">...</td>
    </tr>
  </tbody>
</table>
<p align="center"><em>Covariate_file.txt</em></p>

<br>

5.	Load modules needed:
   
    ```bash
    Anaconda3 
    module load R/4.4.1
    module load rstudio
    ```
<br>

6. Install several R packages including pTFCE package via RStudio if not already installed:
   
    ```bash
    install.packages('pacman', repos = "https://cran.rstudio.com")
    library(pacman)
    packages <- c('remotes', 'devtools', 'oro.nifti', 'RNifti')
    do.call(p_load, as.list(packages))
    remotes::install_github("spisakt/pTFCE@v0.2.2.1")
    ```
    
   > Based on error messages as toolbox runs, it may be necessary to install other R packages
   
<br>

7.	Raise maximum number of simultaneously open network sockets in your terminal
   
    ```bash
    ulimit -n 5000
    ```
<br>

8.	Adjust `R_modelling_parallel.R` script to limit number of cores to slightly below number that the slurm session has, in 2 places in the script:
   
    ```bash
    # line 110
    cl <- makeCluster(cores)       # change to: cl <- makeCluster(20)
    # line 218
    cl <- makeCluster(num_cores)   # change to: cl <- makeCluster(20)
    ```
<br>
    
9.	Adjust `R_modelling_parallel.R` script in the `/SDL_functions` folder to remove one variable being written:
    
    ```bash
    # line 221
    foreach(i = 1:dim(term_cols)[1], .packages = packages) %dopar% {save_data <-save_data(term_cols[i,]) }   # change to: foreach(i = 1:dim(term_cols)[1], .packages = packages) %dopar% {save_data(term_cols[i, ])  }
    ```
<br>

10.	Load python environment and run `ibmma.py` script
    
    ```bash
    conda activate myenv
    python ibmma.py
    ```
    
       >	There may be a number of other packages that need to be installed, this will be signaled in the terminal by errors in running the `ibmma.py` script
       > ```bash
       > pip install <package_name>
       > ```

