### N.Dzinalija VUmc 2023

### Creates:
### Demographics stats and tables for inhibitory domain analyses (per sample and total across samples)
### SST performance stats and tables
### Demographics stats per clinical group

library(readxl)
library(dplyr)
library(tidyverse)
library(knitr)

# Read in RBA input file for main contrast of interest and SST performance file
setwd("~/my-scratch/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibitory_domain/merged/INHIBITION")
df <- read.csv("RBA_input_INHIBITION_ROI.txt")
SST=read.csv("/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibit_Exec_domain/covariates/Performance_SST.csv") 
SST=SST[,c("New.Sub.ID","Score")]
colnames(SST) <- c("Subj","Accuracy")
df=merge(df,SST,all.x=TRUE)

# Convert long to wide format
df <- df %>% select(-c("ROI","Y"))
df <- df %>% distinct()

covs = df
covs$Dx = factor(covs$Dx)
covs$AO[covs$Dx == "OCD" & covs$AO == "HC"] <- "" ##error spotted here where 4 OCD subjects from Bergen were labeled as 'HC' for onset analyses when age of onset was in fact missing



### Calculate demographics
OCD = covs[covs$Dx=="OCD",]
HC = covs[covs$Dx=="HC",]

total_OCD = nrow(OCD)
total_HC = nrow(HC)

#SEX
OCD_male = sum(OCD$SEX=="m") 
OCD_male_perc = round((OCD_male/total_OCD)*100,2)
OCD_female = sum(OCD$SEX=="f")
OCD_female_perc = round((OCD_female/total_OCD)*100,2)

HC_male = sum(HC$SEX=="m") 
HC_male_perc = round((HC_male/total_HC)*100,2)
HC_female = sum(HC$SEX=="f")
HC_female_perc = round((HC_female/total_HC)*100,2)

#Chi-square test of sex differences by diagnosis group
sex_table = table(covs$SEX, covs$Dx)
chi_square_sex = chisq.test(sex_table)
chi_square_sex_stat = round(chi_square_sex$statistic,2)
chi_square_sex_p = round(chi_square_sex$p.value,2)

#Age
OCD_age_mean = round(mean(OCD$AGE),2)
OCD_age_sd = round(sd(OCD$AGE),2)

OCD_pediatric = length(OCD$AGE[OCD$AGE<18])
OCD_pediatric_perc = round((OCD_pediatric/total_OCD)*100,2)
OCD_adult = length(OCD$AGE[OCD$AGE>=18])
OCD_adult_perc = round((OCD_adult/total_OCD)*100,2)

HC_age_mean =  round(mean(HC$AGE),2)
HC_age_sd =  round(sd(HC$AGE),2)

HC_pediatric = length(HC$AGE[HC$AGE<18])
HC_pediatric_perc = round((HC_pediatric/total_HC)*100,2)
HC_adult = length(HC$AGE[HC$AGE>=18])
HC_adult_perc = round((HC_adult/total_HC)*100,2)

#T-test of age differences by diagnosis group
t_test_age = t.test(covs$AGE ~ covs$Dx, var.equal=TRUE)
t_test_age_stat = round(t_test_age$statistic,2)
t_test_age_dof = round(t_test_age$parameter)
t_test_age_p = round(t_test_age$p.value,2)

#Age of onset
table_AO = table(OCD['AO'],useNA ="ifany")
OCD_adult_onset = table_AO[2]
OCD_adult_onset_perc = round((OCD_adult_onset/total_OCD)*100,2)

OCD_child_onset = table_AO[3]
OCD_child_onset_perc = round((OCD_child_onset/total_OCD)*100,2)

OCD_missing_onset = table_AO[1]
OCD_missing_onset_perc = round((OCD_missing_onset/total_OCD)*100,2)

#Medication
table_MED = table(OCD['MED'],useNA ="ifany")
OCD_medicated = table_MED[2]
OCD_medicated_perc = round((OCD_medicated/total_OCD)*100,2)

OCD_unmedicated = table_MED[3]
OCD_unmedicated_perc = round((OCD_unmedicated/total_OCD)*100,2)

OCD_missing_med = table_MED[1]
OCD_missing_med_perc = round((OCD_missing_med/total_OCD)*100,2)

#YBOCS
OCD_YBOCS_mean = round(mean(OCD$YBOCS,na.rm = TRUE),2)
OCD_YBOCS_sd = round(sd(OCD$YBOCS,na.rm = TRUE),2)
OCD_missing_YBOCS = sum(is.na(OCD$YBOCS))
OCD_missing_YBOCS_perc = round((OCD_missing_YBOCS/total_OCD)*100,2)

#Make summary table for all sites combined

Summary_all_sites= data.frame(matrix(NA, nrow = 16, ncol = 4))

colnames(Summary_all_sites) = c("Demographics","OCD", "HC", "Statistics")

Summary_all_sites$Demographics = c("Sex", 
                                   "n female",
                                   "n male",
                                   "Age",
                                   "n <18",
                                   "n >18",
                                   "Age of onset",
                                   "n onset <18",
                                   "n onset >18",
                                   "missing data",
                                   "Medication",
                                   "n medicated",
                                   "n unmedicated",
                                   "missing data",
                                   "YBOCS",
                                   "missing data")

Summary_all_sites$OCD = c("",
                          paste(OCD_female," (",OCD_female_perc,"%)",sep=""),
                          paste(OCD_male," (",OCD_male_perc,"%)",sep=""), 
                          paste(OCD_age_mean," (",OCD_age_sd,")",sep=""),
                          paste(OCD_pediatric," (",OCD_pediatric_perc,"%)",sep=""),
                          paste(OCD_adult," (",OCD_adult_perc,"%)",sep=""),
                          "",
                          paste(OCD_child_onset," (",OCD_child_onset_perc,"%)",sep=""),
                          paste(OCD_adult_onset," (",OCD_adult_onset_perc,"%)",sep=""),
                          paste(OCD_missing_onset," (",OCD_missing_onset_perc,"%)",sep=""),
                          "",
                          paste(OCD_medicated," (",OCD_medicated_perc,"%)",sep=""),
                          paste(OCD_unmedicated," (",OCD_unmedicated_perc,"%)",sep=""),
                          paste(OCD_missing_med," (",OCD_missing_med_perc,"%)",sep=""),
                          paste(OCD_YBOCS_mean," (",OCD_YBOCS_sd,")",sep=""),
                          paste(OCD_missing_YBOCS," (",OCD_missing_YBOCS_perc,"%)",sep=""))

Summary_all_sites$HC = c("",
                         paste(HC_female," (",HC_female_perc,"%)",sep=""),
                         paste(HC_male," (",HC_male_perc,"%)",sep=""), 
                         paste(HC_age_mean," (",HC_age_sd,")",sep=""),
                         paste(HC_pediatric," (",HC_pediatric_perc,"%)",sep=""),
                         paste(HC_adult," (",HC_adult_perc,"%)",sep=""),
                         "-",
                         "-",
                         "-",
                         "-",
                         "-",
                         "-",
                         "-",
                         "-",
                         "-",
                         "-")

Summary_all_sites$Statistics = c("",
                                 paste("X2(1) = ",chi_square_sex_stat,", P = ",chi_square_sex_p,sep=""),
                                 "-",
                                 paste("T(",t_test_age_dof,") = ",t_test_age_stat,", P = ",t_test_age_p,sep=""),
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-",
                                 "-")

kable(Summary_all_sites)


### Demographics tables for executive domain per sample 

per_site=data.frame()
all_sites=data.frame()

for (sample in unique(covs$Sample)){
  print(sample)
  
  sub_sample=covs[covs$Sample==sample,]
  
  sub_sample_OCD_n = sum(sub_sample$Dx=="OCD")
  sub_sample_HC_n = sum(sub_sample$Dx=="HC")
  
  sub_sample_age_mean = round(mean(sub_sample$AGE),2)
  sub_sample_age_sd = round(sd(sub_sample$AGE),2)
  
  sub_sample_sex_male = sum(sub_sample$SEX=="m")
  sub_sample_sex_male_perc = round(sub_sample_sex_male/nrow(sub_sample)*100,2)
  
  sub_sample_child_onset = sum(sub_sample$AO=="Child", na.rm = TRUE)
  sub_sample_child_onse_perc = round(sub_sample_child_onset/sub_sample_OCD_n*100,2)
  
  sub_sample_med = sum(sub_sample$MED=="Med", na.rm = TRUE)
  sub_sample_med_perc = round(sub_sample_med/sub_sample_OCD_n*100,2)
  
  sub_sample_ybocs_mean = round(mean(sub_sample$YBOCS[sub_sample$Dx=="OCD"], na.rm = TRUE),2)
  sub_sample_ybocs_sd = round(sd(sub_sample$YBOCS[sub_sample$Dx=="OCD"], na.rm = TRUE),2)
  
  sub_sample_SST_accuracy_mean = round(mean(sub_sample$Accuracy, na.rm = TRUE),2)
  sub_sample_SST_accuracy_sd = round(sd(sub_sample$Accuracy, na.rm = TRUE),2)
  
  per_site=data.frame(sample,
                      sub_sample_OCD_n,
                      sub_sample_HC_n,
                      sub_sample_sex_male_perc,
                      paste(sub_sample_age_mean,"±",sub_sample_age_sd),
                      sub_sample_child_onse_perc,
                      sub_sample_med_perc,
                      paste(sub_sample_ybocs_mean,"±",sub_sample_ybocs_sd),
                      paste(sub_sample_SST_accuracy_mean,"±",sub_sample_SST_accuracy_sd))
  
  all_sites=rbind(all_sites,per_site)
}

colnames(all_sites) = c("Sample",
                        "n OCD",
                        "n HC",
                        "% Male",
                        "Age (mean ± SD)",
                        "% Child onset OCD",
                        "% Medicated OCD",
                        "(C)Y-BOCS (mean ± SD)",
                        "SST accuracy (mean ± SD)")
kable(all_sites)
sum(all_sites$`n OCD`)
sum(all_sites$`n HC`)


### SST performance

covs = covs[!is.na(covs$Accuracy),]

SST_per_site=data.frame()
SST_all_sites=data.frame()

for (sample in unique(covs$Sample)){
  print(sample)
  
  sub_sample=covs[covs$Sample==sample,]
  
  #Accuracy
  OCD_accuracy_mean = round(mean(sub_sample$Accuracy[sub_sample$Dx=="OCD"]),2)
  OCD_accuracy_sd = round(sd(sub_sample$Accuracy[sub_sample$Dx=="OCD"]),2)
    
  HC_accuracy_mean =  round(mean(sub_sample$Accuracy[sub_sample$Dx=="HC"]),2)
  HC_accuracy_sd =  round(sd(sub_sample$Accuracy[sub_sample$Dx=="HC"]),2)
    
  #T-test of age differences by diagnosis group
  t_test_accuracy = t.test(sub_sample$Accuracy ~ sub_sample$Dx, var.equal=TRUE)
  t_test_accuracy_stat = round(t_test_accuracy$statistic,2)
  t_test_accuracy_dof = round(t_test_accuracy$parameter)
  t_test_accuracy_p = round(t_test_accuracy$p.value,2)
    
  SST_per_site=data.frame(sample,
                          paste(OCD_accuracy_mean,"±",OCD_accuracy_sd),
                          paste(HC_accuracy_mean,"±",HC_accuracy_sd),
                          paste("T(",t_test_accuracy_dof,") = ",t_test_accuracy_stat,", P = ",t_test_accuracy_p,sep=""))
    
  
  SST_all_sites=rbind(SST_all_sites,SST_per_site)

}

colnames(SST_all_sites) = c("Sample",
                        "OCD Accuracy (mean ± SD)",
                        "HC Accuracy (mean ± SD)",
                        "Statistic")

kable(SST_all_sites)


### Demographics tables for executive domain per clinical group

covs_NoHC = covs[covs$AO != "HC",]

# By age of onset
  demographics_table_AO <- covs_NoHC %>%
  group_by(AO) %>%
  summarise(
    n = n(),
    n_female = sum(SEX == "f"),
    perc_female = round((n_female / n) * 100, 1),
    n_male = sum(SEX == "m"),
    perc_male = round((n_male / n) * 100, 1),
    mean_age = round(mean(AGE, na.rm = TRUE), 2),
    sd_age = round(sd(AGE, na.rm = TRUE), 2),
    n_under18 = sum(AGE < 18, na.rm = TRUE),
    perc_under18 = round((n_under18 / n) * 100, 1),
    n_18plus = sum(AGE >= 18, na.rm = TRUE),
    perc_18plus = round((n_18plus / n) * 100, 1),
    n_onset_under18 = sum(AO == "Child", na.rm = TRUE),
    perc_onset_under18 = round((n_onset_under18 / n) * 100, 1),
    n_onset_18plus = sum(AO == "Adult", na.rm = TRUE),
    perc_onset_18plus = round((n_onset_18plus / n) * 100, 1),
    n_ao_missing = sum(is.na(AO)),
    perc_missing = round((n_ao_missing / n) * 100, 1),
    n_medicated = sum(MED == "Med"),
    perc_medicated = round((n_medicated / n) * 100, 1),
    n_unmedicated = sum(MED == "Unmed"),
    perc_unmedicated = round((n_unmedicated / n) * 100, 1),
    n_med_missing = sum(is.na(MED)),
    perc_med_missing = round((n_med_missing / n) * 100, 1),
    mean_ybocs = round(mean(YBOCS, na.rm = TRUE), 2),
    sd_ybocs = round(sd(YBOCS, na.rm = TRUE), 2),
    n_ybocs_missing = sum(is.na(YBOCS)),
    perc_ybocs_missing = round((n_ybocs_missing / n) * 100, 1)
  )

# By medication status
covs_NoHC = covs[covs$MED != "HC",]
  
demographics_table_MED <- covs_NoHC %>%
  group_by(MED) %>%
  summarise(
    n = n(),
    n_female = sum(SEX == "f"),
    perc_female = round((n_female / n) * 100, 1),
    n_male = sum(SEX == "m"),
    perc_male = round((n_male / n) * 100, 1),
    mean_age = round(mean(AGE, na.rm = TRUE), 2),
    sd_age = round(sd(AGE, na.rm = TRUE), 2),
    n_under18 = sum(AGE < 18, na.rm = TRUE),
    perc_under18 = round((n_under18 / n) * 100, 1),
    n_18plus = sum(AGE >= 18, na.rm = TRUE),
    perc_18plus = round((n_18plus / n) * 100, 1),
    n_onset_under18 = sum(AO == "Child", na.rm = TRUE),
    perc_onset_under18 = round((n_onset_under18 / n) * 100, 1),
    n_onset_18plus = sum(AO == "Adult", na.rm = TRUE),
    perc_onset_18plus = round((n_onset_18plus / n) * 100, 1),
    n_ao_missing = sum(is.na(AO)),
    perc_missing = round((n_ao_missing / n) * 100, 1),
    n_medicated = sum(MED == "Med"),
    perc_medicated = round((n_medicated / n) * 100, 1),
    n_unmedicated = sum(MED == "Unmed"),
    perc_unmedicated = round((n_unmedicated / n) * 100, 1),
    n_med_missing = sum(is.na(MED)),
    perc_med_missing = round((n_med_missing / n) * 100, 1),
    mean_ybocs = round(mean(YBOCS, na.rm = TRUE), 2),
    sd_ybocs = round(sd(YBOCS, na.rm = TRUE), 2),
    n_ybocs_missing = sum(is.na(YBOCS)),
    perc_ybocs_missing = round((n_ybocs_missing / n) * 100, 1)
  )


### Post-hoc tests carried out to investigate the strong effect of YBOCS on task load activation
setwd("~/my-scratch/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Inhibit_Exec_domain/merged/LOAD")
df <- read.csv("RBA_input_LOAD_ROI_YBOCS.txt", sep = "")

#convert long to wide format
df <- df %>% select(-c("ROI","Y"))
df <- df %>% distinct()

#intersect with covariates from above
new=merge.data.frame(df,covs,all.x=TRUE)

#compare sub-groups
  # Age has strong positive correlation with YBOCS score where adults have higher YBOCS scores 
  # But,age already used as covariate in task load analyses so not very informative
new$Adult[new$AGE<19]="Pediatric"
new$Adult[new$AGE>=19]="Adult"

ggplot(data=new, mapping=aes(x=Adult, y=YBOCS,fill=Adult))+
  geom_bar(stat = "summary")
  
t_test <- t.test(YBOCS ~ Adult, data = new, var.equal = TRUE) # Use var.equal=FALSE if variances are unequal
cor.test(new$AGE,new$YBOCS)
plot(new$AGE,new$YBOCS)
abline(lm(new$YBOCS ~ new$AGE), col = "red", lwd = 3)

  #ybocs score does not differ with regard to medication status
t_test <- t.test(YBOCS ~ MED, data = new, var.equal = TRUE) # Use var.equal=FALSE if variances are unequal


  #late age of OCD onset has greater YBOCS score than early age of onset
new = new[new$AO != "",]
new = new[new$AO != "",]
t_test <- t.test(YBOCS ~ AO, data = new, var.equal = TRUE) # Use var.equal=FALSE if variances are unequal

    #there are also far more (double the number) early-onset individuals in the dataset
ggplot(data=new, mapping=aes(x=factor(AO)))+
  geom_bar(stat = "count")
       



