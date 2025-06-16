library(lme4)
library(lmerTest)  
library(dplyr)

# Read in the dataset
data <- read.table("/data/anw/anw-work/NP/projects/data_ENIGMA_OCD/ENIGMA_TASK/analysis/Executive_domain/merged/PLANNING/RBA_input_PLANNING_ROI_BASE.txt", header = TRUE, sep = "\t")
data$Sample <- as.factor(data$Sample)

# Initialize an empty data frame to store results
p_table <- data.frame(ROI = character(), T_value = numeric(), p_value = numeric(), stringsAsFactors = FALSE)

# Loop through each ROI and fit a mixed-effects model
for (roi in unique(data$ROI)) {
  # Subset data for the current ROI
  roi_data <- data %>% filter(ROI == roi)
  
  # Fit the model with a random intercept for sample
  model <- lmer(Y ~ Dx + AGE + SEX + (1 | Sample), data = roi_data)
  
  # Extract the T-value and p-value for DxOCD
  t_value <- coef(summary(model))["DxOCD", "t value"]
  p_value <- coef(summary(model))["DxOCD", "Pr(>|t|)"]
  
  # Append the results to the data frame
  p_table <- rbind(df, data.frame(ROI = roi, T_value = t_value, p_value = p_value))

}

# Display the final data frame with two forms of multiple comparison correction
p_table$Bonferoni_corr <- p_table$p_value*(length(p_table$p_value))
p_table$Bonferoni_corr[p_table$Bonferoni_corr>1] = 1
p_table$FDR_corr <- p.adjust(p_table$p_value, method = "fdr")
print(p_table)

# Fit one mixed effects model with all ROIs simultaneously
model <- lmer(Y ~ Dx * ROI + AGE + SEX + (1 | Sample/Subj), data = data)
summary(model)

