### N.Dzinalija VUmc 2023

### Once 5_extract_activation_from_ROIs.sh and 6_extract_activation_from_Schaefer_Melbourne_parcels.sh
### have created RBA input datasets, this script filters the output and creates a (final) RBA input
### file that can be passed to RBA slurm scripts for each of the analses:
### Group OCD>HC effect, YBOCS score, Medication status, and Age of Onset 

### It also creates separate output for the Tower of London/Stop-Signal tasks as this was one of sensitivity 
### analyses in executive and inhibitory domains

### It also creates separate output for the pediatric/adult samples as this was one of sensitivity 
### analyses in inhibitory domain

### IMPORTANT: Adjust the child samples in the AO analyses below (IN 2 PLACES!!) to remove those samples 
### (necessary in emotional/executive, but no longer needed in inhibitory domain)

library(dplyr)
library(tidyr)

setwd("/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged")

### ROI (Thorsen/Nitschke/Norman ROIs)

for (i in c("INHIBITION","ERROR")){
  setwd(paste("/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/",i,sep=""))
  RBA_input=read.csv(paste("RBA_input_",i,"_ROI.txt",sep=""))
  
  ## BASE
  BASE_PED = subset(RBA_input[RBA_input$AGEGROUP=="CHILD",], select = -c(AGEGROUP, TASK, YBOCS, MED, AO))
  BASE_ADULT = subset(RBA_input[(RBA_input$AGEGROUP=="ADULT" & RBA_input$AGE>=18),], select = -c(AGEGROUP, TASK, YBOCS, MED, AO))
  BASE_ADULT_SST = subset(RBA_input[(RBA_input$AGEGROUP=="ADULT" & RBA_input$AGE>=18 & RBA_input$TASK=="SST"),], select = -c(AGEGROUP, TASK, YBOCS, MED, AO))
  write.table(BASE_PED, file = paste("RBA_input_",i,"_ROI_BASE_PED.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(BASE_ADULT, file = paste("RBA_input_",i,"_ROI_BASE_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(BASE_ADULT_SST, file = paste("RBA_input_",i,"_ROI_BASE_SST.txt",sep=""), sep = "\t", row.names = FALSE)
  
  ## YBOCS
  YBOCS = RBA_input[RBA_input$Dx=="OCD",]  
  YBOCS_PED = subset(YBOCS[YBOCS$AGEGROUP=="CHILD",], select = -c(AGEGROUP, TASK, Dx, MED, AO)) 
  YBOCS_ADULT = subset(YBOCS[(YBOCS$AGEGROUP=="ADULT" & YBOCS$AGE>=18),], select = -c(AGEGROUP, TASK, Dx, MED, AO)) 
  YBOCS_ADULT_SST = subset(YBOCS[(YBOCS$AGEGROUP=="ADULT" & YBOCS$AGE>=18 & YBOCS$TASK=="SST"),], select = -c(AGEGROUP, TASK, Dx, MED, AO))
  write.table(YBOCS_PED, file = paste("RBA_input_",i,"_ROI_YBOCS_PED.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(YBOCS_ADULT, file = paste("RBA_input_",i,"_ROI_YBOCS_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(YBOCS_ADULT_SST, file = paste("RBA_input_",i,"_ROI_YBOCS_SST.txt",sep=""), sep = "\t", row.names = FALSE)
  
  ## MED
  MED = RBA_input[!RBA_input$MED=="",]
  MED_PED = subset(MED[MED$AGEGROUP=="CHILD",], select = -c(AGEGROUP, TASK, Dx, YBOCS, AO)) 
  MED_ADULT = subset(MED[(MED$AGEGROUP=="ADULT" & MED$AGE>=18),], select = -c(AGEGROUP, TASK, Dx, YBOCS, AO))
  MED_ADULT_SST = subset(MED[(MED$AGEGROUP=="ADULT" & MED$AGE>=18 & MED$TASK=="SST"),], select = -c(AGEGROUP, TASK, Dx, YBOCS, AO))
  write.table(MED_PED, file = paste("RBA_input_",i,"_ROI_MED_PED.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(MED_ADULT, file = paste("RBA_input_",i,"_ROI_MED_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(MED_ADULT_SST, file = paste("RBA_input_",i,"_ROI_MED_SST.txt",sep=""), sep = "\t", row.names = FALSE)
  
  ## AO
  # Remove all child samples (investigate only adult samples)
  AO = RBA_input[!RBA_input$AO=="",]
  AO_ADULT = subset(AO[(AO$AGEGROUP=="ADULT" & AO$AGE>=18),], select = -c(AGEGROUP, TASK, Dx, YBOCS, MED)) 
  AO_ADULT_SST = subset(AO[(AO$AGEGROUP=="ADULT" & AO$AGE>=18 & AO$TASK=="SST"),], select = -c(AGEGROUP, TASK, Dx, YBOCS, MED)) 
  write.table(AO_ADULT, file = paste("RBA_input_",i,"_ROI_AO_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
  write.table(AO_ADULT_SST, file = paste("RBA_input_",i,"_ROI_AO_SST.txt",sep=""), sep = "\t", row.names = FALSE)
}



### Whole-brain (Schaefer 200/400 cortical ROIs and Melbourne 32 subcortical ROIs)
for (j in c("200")){
  for (i in c("INHIBITION","ERROR")){
    setwd(paste("/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/",i,sep=""))
    RBA_input=read.csv(paste("RBA_input_",i,"_Schaefer",j,".txt",sep=""))
    
    ## Rename ROIs
    # 7 networks
    RBA_input$ROI=gsub("Vis", "Visual", RBA_input$ROI)
    RBA_input$ROI=gsub("SomMot", "Somatomotor", RBA_input$ROI)
    RBA_input$ROI=gsub("DorsAttn", "Dorsal Attention", RBA_input$ROI)
    RBA_input$ROI=gsub("SalVentAttn", "Salience / Ventral Attention", RBA_input$ROI)
    RBA_input$ROI=gsub("Cont", "Control", RBA_input$ROI)
    RBA_input$ROI=gsub("_", " ", RBA_input$ROI)
    
    for (k in seq_along(RBA_input$ROI)) {
      if (grepl("^LH|^RH", RBA_input$ROI[k])) {
        parts <- unlist(strsplit(RBA_input$ROI[k], " ", fixed = TRUE))
        direction <- substr(parts[1], 1, 1)
        parts <- parts[-1]
        RBA_input$ROI[k] <- paste(paste(parts, collapse = " "), direction, sep = " ")
      }
    }
    
    # Subcortical
    RBA_input$ROI=gsub("aHIP", "Hippocampus Ant", RBA_input$ROI)
    RBA_input$ROI=gsub("pHIP", "Hippocampus Post", RBA_input$ROI)
    RBA_input$ROI=gsub("lAMY", "Amygdala Lat", RBA_input$ROI)
    RBA_input$ROI=gsub("mAMY", "Amygdala Med", RBA_input$ROI)
    RBA_input$ROI=gsub("THA-DP", "Thalamus DorsopPost", RBA_input$ROI)
    RBA_input$ROI=gsub("THA-VP", "Thalamus VentroPost", RBA_input$ROI)
    RBA_input$ROI=gsub("THA-VA", "Thalamus VentroAnt", RBA_input$ROI)
    RBA_input$ROI=gsub("THA-DA", "Thalamus DorsoAnt", RBA_input$ROI)
    RBA_input$ROI=gsub("NAc-shell", "Nucleus Accumbens shell", RBA_input$ROI)
    RBA_input$ROI=gsub("NAc-core", "Nucleus Accumbens core", RBA_input$ROI)
    RBA_input$ROI=gsub("pGP", "Globus Pallidus Post", RBA_input$ROI)
    RBA_input$ROI=gsub("aGP", "Globus Pallidus Ant", RBA_input$ROI)
    RBA_input$ROI=gsub("aPUT", "Putamen Ant", RBA_input$ROI)
    RBA_input$ROI=gsub("pPUT", "Putamen Post", RBA_input$ROI)
    RBA_input$ROI=gsub("aCAU", "Caudate Ant", RBA_input$ROI)
    RBA_input$ROI=gsub("pCAU", "Caudate Post", RBA_input$ROI)
    RBA_input$ROI=gsub("-rh", " R", RBA_input$ROI)
    RBA_input$ROI=gsub("-lh", " L", RBA_input$ROI)
 
    
    ## BASE
    BASE_PED = subset(RBA_input[RBA_input$AGEGROUP=="CHILD",], select = -c(AGEGROUP, TASK, YBOCS, MED, AO))
    BASE_ADULT = subset(RBA_input[(RBA_input$AGEGROUP=="ADULT" & RBA_input$AGE>=18),], select = -c(AGEGROUP, TASK, YBOCS, MED, AO))
    BASE_ADULT_SST = subset(RBA_input[(RBA_input$AGEGROUP=="ADULT" & RBA_input$AGE>=18 & RBA_input$TASK=="SST"),], select = -c(AGEGROUP, TASK, YBOCS, MED, AO))
    write.table(BASE_PED, file = paste("RBA_input_",i,"_Schaefer",j,"_BASE_PED.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(BASE_ADULT, file = paste("RBA_input_",i,"_Schaefer",j,"_BASE_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(BASE_ADULT_SST, file = paste("RBA_input_",i,"_Schaefer",j,"_BASE_SST.txt",sep=""), sep = "\t", row.names = FALSE)
    
    ## YBOCS
    YBOCS = RBA_input[RBA_input$Dx=="OCD",]  
    YBOCS_PED = subset(YBOCS[YBOCS$AGEGROUP=="CHILD",], select = -c(AGEGROUP, TASK, Dx, MED, AO)) 
    YBOCS_ADULT = subset(YBOCS[(YBOCS$AGEGROUP=="ADULT" & YBOCS$AGE>=18),], select = -c(AGEGROUP, TASK, Dx, MED, AO)) 
    YBOCS_ADULT_SST = subset(YBOCS[(YBOCS$AGEGROUP=="ADULT" & YBOCS$AGE>=18 & YBOCS$TASK=="SST"),], select = -c(AGEGROUP, TASK, Dx, MED, AO))
    write.table(YBOCS_PED, file = paste("RBA_input_",i,"_Schaefer",j,"_YBOCS_PED.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(YBOCS_ADULT, file = paste("RBA_input_",i,"_Schaefer",j,"_YBOCS_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(YBOCS_ADULT_SST, file = paste("RBA_input_",i,"_Schaefer",j,"_YBOCS_SST.txt",sep=""), sep = "\t", row.names = FALSE)
    
    ## MED
    MED = RBA_input[!RBA_input$MED=="",]
    MED_PED = subset(MED[MED$AGEGROUP=="CHILD",], select = -c(AGEGROUP, TASK, Dx, YBOCS, AO)) 
    MED_ADULT = subset(MED[(MED$AGEGROUP=="ADULT" & MED$AGE>=18),], select = -c(AGEGROUP, TASK, Dx, YBOCS, AO))
    MED_ADULT_SST = subset(MED[(MED$AGEGROUP=="ADULT" & MED$AGE>=18 & MED$TASK=="SST"),], select = -c(AGEGROUP, TASK, Dx, YBOCS, AO))
    write.table(MED_PED, file = paste("RBA_input_",i,"_Schaefer",j,"_MED_PED.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(MED_ADULT, file = paste("RBA_input_",i,"_Schaefer",j,"_MED_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(MED_ADULT_SST, file = paste("RBA_input_",i,"_Schaefer",j,"_MED_SST.txt",sep=""), sep = "\t", row.names = FALSE)
    
    ## AO
    # Remove all child samples (investigate only adult samples)
    AO = RBA_input[!RBA_input$AO=="",]
    AO_ADULT = subset(AO[(AO$AGEGROUP=="ADULT" & AO$AGE>=18),], select = -c(AGEGROUP, TASK, Dx, YBOCS, MED)) 
    AO_ADULT_SST = subset(AO[(AO$AGEGROUP=="ADULT" & AO$AGE>=18 & AO$TASK=="SST"),], select = -c(AGEGROUP, TASK, Dx, YBOCS, MED)) 
    write.table(AO_ADULT, file = paste("RBA_input_",i,"_Schaefer",j,"_AO_ADULT.txt",sep=""), sep = "\t", row.names = FALSE)
    write.table(AO_ADULT_SST, file = paste("RBA_input_",i,"_Schaefer",j,"_AO_SST.txt",sep=""), sep = "\t", row.names = FALSE)
  }
}

