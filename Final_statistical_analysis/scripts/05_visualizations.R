# Original prediction plots and figure exports.

# 8) Plot
p_binary <- ggplot(emm_df, aes(x=c.dilemma, y=prob, fill=c.group)) +
  geom_col(position = position_dodge(width=0.915)) +
facet_wrap(~c.risk) +
scale_y_continuous(
  limits = c(0,1),
  breaks = seq(0,0.8, by=0.2),
  labels = label_percent(accuracy=1),
  expand = c(0,0) # zero touches the x-axis
) +
labs(
    x = "Dilemma type",
    y = "Predicted probability of yes responses",
    fill = "Group",
    title = "Percentage of Utilitarian Choices"
  )


# Plot
p_filler_binary <- ggplot(data = YN_F) + 
  aes(x = interaction(dilemma_type, group), y = affirmative_response_total) +
  stat_summary(fun = mean, geom = "bar", fill = "skyblue") +
  labs(y = "Percentage Affirmative", title = "Mean Affirmative Responses (Filler)") +
  theme_minimal()


# 5. Plot 
# 5.1) Model plot mean + pred prob
p_meanAD <- ggplot(
  emm_dfAD_mean,
  aes(
    x = c.dilemma,
    y = mean.class,
    colour = c.group
  )
) +
  geom_point(
    position = position_dodge(width = 0.45),
    size = 3
  ) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    position = position_dodge(width = 0.45),
    width = 0.15,
    linewidth = 0.6
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    limits = c(1, 9),
    breaks = 1:9
  ) +
  labs(
    title = "A. Estimated Arousal Mean Responses",
    x = "Dilemma type",
    y = "Estimated mean arousal response",
    colour = "Group"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )
p_meanAD

p_probAD <- ggplot(
  emm_dfAD_prob,
  aes(
    x = answer,
    y = prob,
    group = interaction(c.group, c.dilemma),
    colour = c.group,
    linetype = c.dilemma
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    width = 0.08,
    linewidth = 0.4
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, NA)
  ) +
  labs(
    title = "B. Predicted Arousal Response Probabilities",
    x = "Arousal response category",
    y = "Predicted probability",
    colour = "Group",
    linetype = "Dilemma type"
  ) +
  guides(
    colour = "none",   # removes duplicate Group colour legend
    linetype = guide_legend(title = "Dilemma type")
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_probAD
p_combinedAD <- p_meanAD + p_probAD +
  plot_layout(
    ncol = 2,
    widths = c(1, 1.35),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )
p_probAD 
p_combinedAD

ggsave(
  filename = "AD_CLMM_combined_plot.png",
  path = output_dir,
  plot = p_combinedAD,
  width = 13,
  height = 6.5,
  dpi = 300
)

# # 5.2) Raw data plot 
# p_obsAD <- ggplot(AD, aes(x = dilemma_type, y = answer, fill = group)) +
#   geom_boxplot(
#     position = position_dodge(width = 0.8),
#     width = 0.6,
#     alpha = 0.7,
#     outlier.shape = NA
#   ) +
#   facet_wrap(~ risk) +
#   scale_y_continuous(
#     breaks = 1:9,
#     limits= c(1,9)
#   ) +
#   labs(
#     x = "Dilemma type",
#     y = "Answer",
#     fill = "Group"
#   )


# 5. Plot ----------------------------------------------------------------

# 5.1 Estimated mean response plot
p_meanVD <- ggplot(
  emm_dfVD_mean,
  aes(
    x = c.dilemma,
    y = mean.class,
    colour = c.group
  )
) +
  geom_point(
    position = position_dodge(width = 0.45),
    size = 3
  ) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    position = position_dodge(width = 0.45),
    width = 0.15,
    linewidth = 0.6
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    limits = c(1, 9),
    breaks = 1:9
  ) +
  labs(
    title = "A. Estimated Valence Mean Responses",
    x = "Dilemma type",
    y = "Estimated mean response",
    colour = "Group"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_meanVD


# 5.2 Predicted response probabilities
p_probVD <- ggplot(
  emm_dfVD_prob,
  aes(
    x = answer,
    y = prob,
    group = interaction(c.group, c.dilemma),
    colour = c.group,
    linetype = c.dilemma
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    width = 0.08,
    linewidth = 0.4
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, NA)
  ) +
  labs(
    title = "B. Predicted Valence Response Probabilities",
    x = "Response category",
    y = "Predicted probability",
    colour = "Group",
    linetype = "Dilemma type"
  ) +
  guides(
    colour = "none",
    linetype = guide_legend(title = "Dilemma type")
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_probVD


# 5.3 Combined figure
p_combinedVD <- p_meanVD + p_probVD +
  plot_layout(
    ncol = 2,
    widths = c(1, 1.35),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )

p_combinedVD


# 5.4 Save figure
ggsave(
  filename = "VD_CLMM_combined_plot.png",
  path = output_dir,
  plot = p_combinedVD,
  width = 13,
  height = 6.5,
  dpi = 300
)


# 5. Plot ---------------------------------------------------------------

# 5.1 Estimated mean response plot
p_meanMAD <- ggplot(
  emm_dfMAD_mean,
  aes(
    x = c.risk,
    y = mean.class,
    colour = c.group
  )
) +
  geom_point(
    position = position_dodge(width = 0.45),
    size = 3
  ) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    position = position_dodge(width = 0.45),
    width = 0.15,
    linewidth = 0.6
  ) +
  facet_wrap(~ c.dilemma) +
  scale_y_continuous(
    limits = c(1, 9),
    breaks = 1:9
  ) +
  labs(
    title = "A. Estimated Moral Acceptability Mean Responses",
    x = "Dilemma type",
    y = "Estimated mean response",
    colour = "Group"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_meanMAD


# 5.2 Predicted response probabilities
p_probMAD <- ggplot(
  emm_dfMAD_prob,
  aes(
    x = answer,
    y = prob,
    group = interaction(c.group, c.risk),
    colour = c.group,
    linetype = c.risk
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    width = 0.08,
    linewidth = 0.4
  ) +
  facet_wrap(~ c.dilemma) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, NA)
  ) +
  labs(
    title = "B. Predicted Moral Acceptability response probabilities",
    x = "Response category",
    y = "Predicted probability",
    colour = "Group",
    linetype = "Risk"
  ) +
  guides(
    colour = "none",
    linetype = guide_legend(title = "Risk")
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_probMAD


# 5.3 Combined figure
p_combinedMAD <- p_meanMAD + p_probMAD +
  plot_layout(
    ncol = 2,
    widths = c(1, 1.35),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )

p_combinedMAD


# 5.4 Save figure
ggsave(
  filename = "MAD_CLMM_combined_plot.png",
  path = output_dir,
  plot = p_combinedMAD,
  width = 13,
  height = 6.5,
  dpi = 300
)


# Save the two existing binary figures for later viewing.
# These plots are assigned above; statistical calculations are unchanged.
ggsave(filename = "binary_predicted_probabilities.png", path = output_dir,
       plot = p_binary, width = 10, height = 6, dpi = 300)
ggsave(filename = "filler_binary_observed.png", path = output_dir,
       plot = p_filler_binary, width = 10, height = 6, dpi = 300)
