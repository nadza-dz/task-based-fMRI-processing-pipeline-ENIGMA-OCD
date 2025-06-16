### Nadza Dzinalija Sept 2023
### Produces plots to summarize jackknife leave-one-site-out analysees
### Designed for use with raincloud_plot.R function

library(tidyr)
library(dplyr)

setwd("/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/scripts/tb_mega_pipeline")
source("raincloud_plot.R")

# IMPORTANT: list ROIs in order they appear in ps0 or psa variables in .RData file, 
# So alphabetical but capital names go before lowercase (ie, dlPFC will go after SMA)

for (contrast in c("INHIBITION","ERROR")){
  ROIfile <- read.csv(c(paste0("~/my-scratch/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/",contrast,"/RBA_input_",contrast,"_ROI.txt")))
  ROIs <- sort(unique(ROIfile$ROI), method = "radix") # sort ROIs by current RBA sorting (uppercase first)
  ROIs <- gsub("_l$", " (L)", ROIs)
  ROIs <- gsub("_r$", " (R)", ROIs)
  
  for (model in c("AO", "BASE", "MED", "YBOCS")){
      
    for (group in c("ADULT","SST","PED")){ 
      
      setwd(paste0("~/my-scratch/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/RBA/ROI/", contrast, "/", model, "/", group, "/Leave_one_site_out"))
        
      ### Input for raincloud plot function
  
      P_plus_values_list <- list()
  
      for (site in list.dirs(getwd())[2:length(list.dirs(getwd()))]){
        setwd(site)
        
        leave_out <- tail(strsplit(site, "/")[[1]],1)
  
        if (leave_out=="Leave_out_VUmc_VENI"){
          site_label <- "Amsterdam, NLD I"
        } else if (leave_out=="Leave_out_VUmc_TIPICCO"){
          site_label <- "Amsterdam, NLD II"
        } else if (leave_out=="Leave_out_TBM_OCD"){
          site_label <- "Amsterdam, NLD III"
        } else if (leave_out=="Leave_out_COIMBRA"){
          site_label <- "Coimbra, PRT"
          } else if (leave_out=="Leave_out_IDIBELL_15T"){
          site_label <- "Barcelona, ESP I"
        } else if (leave_out=="Leave_out_IDIBELL_3T"){
          site_label <- "Barcelona, ESP II"
        } else if (leave_out=="Leave_out_BARCELONA"){
          site_label <- "Barcelona, ESP III"
        } else if (leave_out=="Leave_out_NIMHANS_GONOGO"){
          site_label <- "Bangalore, IND"
        } else if (leave_out=="Leave_out_BERGEN_B4DT"){
          site_label <- "Bergen, NOR"
        } else if (leave_out=="Leave_out_HUB_3T"){
          site_label <- "Berlin, GER"
        } else if (leave_out=="Leave_out_SEQ_1_NKI"){
          site_label <- "New York, USA"
        } else if  (leave_out=="Leave_out_MUC_TUM"){
          site_label <- "Munich, GER"
        } else if (leave_out=="Leave_out_SEOUL_SST"){
          site_label <- "Seoul, KOR"
        } else if (leave_out=="Leave_out_UZH_OCD"){
          site_label <- "Zurich, CHE"
        } 
          
        ### Extract level comparisons
  
        Rdatafile <-list.files(pattern = ".RData")
        load(Rdatafile)
        
        # Create an empty list to store input variables
        input_list <- list()  
  
        # For continuous data
        if(any(!is.na(lop$EOIq) == TRUE)){
          
          input <- ps0
          label <- paste0(contrast,"_",lop$EOIq)
          input_list[[label]] <- input
  
        } 
        
        # For categorical data
        if(any(!is.na(lop$EOIc) == TRUE)) for(ii in 1:length(lop$EOIc)) {
          
            for(jj in 1:(nl-1)) for(kk in (jj+1):nl) {
              if (lvl[jj] == "HC"){
                input <- psa[kk,,] - psa[jj,,]
                label <- paste0(contrast, "_", lop$EOIc[ii], '-', lvl[kk], '-vs-', lvl[jj])
              
              } else {
                input <- psa[jj,,] - psa[kk,,]
                label <- paste0(contrast, "_", lop$EOIc[ii], '-', lvl[jj], '-vs-', lvl[kk])
              }
              
              input_list[[label]] <- input
            }
          }
        
        # determine sample size of the left-out sample
        setwd(paste0("~/my-scratch/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/RBA/ROI/",contrast,"/",model,"/",group))
        Rdatafile <-list.files(pattern = ".RData")
        load(Rdatafile)
        left_out_sample <- sub("Leave_out_", "", leave_out)
        sample_size <- length(unique(lop$dataTable$Subj[lop$dataTable$Sample==left_out_sample]))
        
        # append processed input variables to P_plus_values_list
        for (input_name in names(input_list)) {
          input <- input_list[[input_name]]
          colnames(input)= ROIs
          data <- data.frame(input)
          nobj = dim(data)[1]
          rois <- dimnames(input)[[2]]
          colnames(data) <- rois
          data_stats <- data.frame(rep(site_label,length(rois)))
          data_stats$ROI <- rois
          data_stats$P <- colSums(data > 0)/nobj
          data_stats$N <- sample_size
          colnames(data_stats) <- c("Leave out", "ROI","P","N")
              
          P_plus_values_list[[input_name]] <- rbind(P_plus_values_list[[input_name]],data_stats)
        }
      }
      
      # create figure from each input in P_plus_values_list
      for (effect in names(P_plus_values_list)) {
        P_plus_values <- P_plus_values_list[[effect]]  
        P_plus_values$`Leave out` <- factor(P_plus_values$`Leave out`, levels=sort(levels(factor(P_plus_values$`Leave out`))))
    
        setwd(paste0("~/my-scratch/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/RBA/ROI/",contrast,"/",model,"/",group,"/Leave_one_site_out"))
        raincloud_plot(P_plus_values,effect,8,6)
        
        # write out csv with range of P+ values in leave-site-out jackknife analyses
        min_max_P_plus <- P_plus_values %>%
          group_by(ROI) %>%
          summarise(Min_P = round(min(P),2),
                    Max_P = round(max(P),2))
        write.csv(min_max_P_plus,paste0(effect,"_P_plus_range.csv"),row.names = FALSE)
              
      }
      }
    }
}



  







