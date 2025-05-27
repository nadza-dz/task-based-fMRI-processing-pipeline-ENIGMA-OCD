### Nadza Dzinalija Sept 2023
### Produces raincloud plot with P+ values from jackknife leave-one-site-out analyses
### Designed for use with ROI_jackknife_raincloud_plots.R script


raincloud_plot <-function (dat, label, wi, hi) 
{
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(ggrain)
  
  # raincloud plot  
  ggplot(dat,aes(x = ROI, y = P)) +
    geom_rain(cov = "Leave out",
              boxplot.args.pos = list(width = 0.1, position = position_nudge(x = 0.2)),
              violin.args.pos = list(side = "r",width = 1.5, position = position_nudge(x = 0.35))) +
    theme_classic()+
    theme(axis.text.x = element_text(size = 12, angle = 45, hjust=1),
          axis.text.y = element_text(size = 12),
          axis.title.x = element_text(size = 14),
          axis.title.y = element_text(size = 14),
          legend.text = element_text(size = 11),
          legend.title = element_text(size = 13))+
    scale_y_continuous("Positive Posterior Probability (P+)",breaks = seq(0,1,0.1), limits = c(0,1),expand = c(0, 0))+
    scale_x_discrete(expand = c(0, 0))
  
  
  ggsave(file = paste0(label, "_raincloud.jpg"), width = wi, height = hi, 
         dpi = 500)

  # boxplot  
  ggplot(dat, aes(x = ROI, y = P)) +
    geom_jitter(position = position_nudge(x = -0.2), aes(color = `Leave out`, size = N), alpha = 0.8) +
    geom_boxplot(position = position_nudge(x = 0.1), width = 0.2, outlier.shape = NA, fill = "grey",show.legend = FALSE) +
    theme_classic() +
    theme(axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
          axis.text.y = element_text(size = 12),
          axis.title.x = element_text(size = 14),
          axis.title.y = element_text(size = 14),
          legend.text = element_text(size = 11),
          legend.title = element_text(size = 13)) +
    guides(color = guide_legend(title = "Leave out sample", order = 1), size = guide_legend(title = "Sample size", order = 2)) + 
    scale_y_continuous("Positive Posterior Probability (P+)", breaks = seq(0, 1, 0.1), limits = c(0, 1), expand = c(0, 0)) 
  
  ggsave(file = paste0(label, "_boxplot.jpg"), width = wi, height = hi, dpi = 500)
  
}


