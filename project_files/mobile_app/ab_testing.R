library(readr)
library(dplyr)

# importing data
cookie_cats <- read_csv("cookie_cats.csv",
                        col_types = cols(version = col_factor()))
print(summary(cookie_cats$total_rounds))
print(table(cookie_cats$version))

# removing users with 0 rounds played and outliers
cookie_cats_clean <- cookie_cats %>% 
  filter(total_rounds >= 30, total_rounds <= 45000)

print(summary(cookie_cats_clean$total_rounds))
print(table(cookie_cats_clean$version))


# ---- CONTINUOUS ANALYSIS ----
library(ggplot2)

# creating quantitative data frame
cookie_cats_rou <- cookie_cats_clean %>%
  select(version, total_rounds)

# visualizing distribution of gate version split
agg_data <- cookie_cats_rou %>%
  group_by(version) %>%
  summarise(count = n())

ggplot(agg_data, aes(x = version, y = count)) +
  geom_bar(stat = "identity", fill="steelblue") +
  labs(title = "User Counts per Gate Version",
       x = "Gate Version",
       y = "User Count") +
  theme_grey()

# visualizing distribution of total rounds played per gate version (up to 3rd)
agg_data <- cookie_cats_rou %>%
  group_by(total_rounds, version) %>%
  summarise(count = n()) %>%
  ungroup()

ggplot(agg_data, aes(x = total_rounds, y = count, color = version)) +
  geom_line(size = 0.8, alpha = 0.8) +
  labs(title = "User Counts per Total Rounds Played",
       x = "Total Rounds Played",
       y = "User Count",
       color = "Version") +
  theme_grey() +
  xlim(30, 144)

# Mann-Whitney U test
mwu_result <- wilcox.test(total_rounds ~ version, data = cookie_cats_rou)
print(mwu_result)

# bootstrapping means
set.seed(24)
sampling_means <- data.frame(version = factor(), sample_mean = numeric())
for(i in 1:10000){
  sample_g30 <- cookie_cats_rou %>% 
    filter(version == 'Gate 30') %>% 
    sample_n(nrow(cookie_cats_rou), replace = TRUE) %>% 
    summarise(mean_rounds = mean(total_rounds))
  sample_g40 <- cookie_cats_rou %>% 
    filter(version == 'Gate 40') %>% 
    sample_n(nrow(cookie_cats_rou), replace = TRUE) %>% 
    summarise(mean_rounds = mean(total_rounds))
  sampling_means <- rbind(sampling_means, 
                             data.frame(version = c('Gate 30', 'Gate 40'), 
                                        mean_rounds = c(sample_g30$mean_rounds, 
                                                        sample_g40$mean_rounds)))
}

ggplot(sampling_means, aes(x = mean_rounds, color = version)) +
  geom_density(size = 0.8, alpha = 0.8) +
  labs(title = "Density Plots for Mean Rounds Played",
       x = "Mean Rounds Played",
       y = "Density",
       color = "Version") +
  theme_grey()

# sampling mean differences
differences <- data.frame(difference = numeric(0))
for(i in seq_len(nrow(sampling_means))) {
  if(i %% 2 == 0) {
    diff_value <- sampling_means$mean_rounds[i] - sampling_means$mean_rounds[i + 1]
    differences <- rbind(differences, data.frame(difference = diff_value))
  }
}

ggplot(differences, aes(x = difference)) +
  geom_histogram(bins = 20, width=0.15, fill = "steelblue", color="black") +
  labs(title = "Histogram of Mean Differences (Gate 40 - Gate 30)",
       x = "Difference in Mean Rounds Played",
       y = "Frequency") + 
  theme_grey()

print(paste0("Mean Difference in Mean Rounds Played: ", 
             round(mean(differences$difference, na.rm = TRUE),3)))

# ---- CATEGORICAL ANALYSIS ----

# # creating categorical data frame
cookie_cats_ret <- cookie_cats %>%
  select(version, 'one_d_retention', 'seven_d_retention')

# checking chi-square assumptions
cookie_cats_ret %>%
  group_by(version) %>%
  summarise(
    '1 Day Retention' = n(),
    '7 Day Retention' = n()
  ) %>%
  ungroup() %>%
  mutate(row_number = row_number()) %>%
  select(-row_number)

for(retention in c('one_d_retention', 'seven_d_retention')) {
  print(retention)
  print(table(cookie_cats_ret$version, cookie_cats_ret[[retention]]))
}

# performing chi-square
for(retention in c('one_d_retention', 'seven_d_retention')) {
  contingency_table <- table(cookie_cats_ret$version, cookie_cats_ret[[retention]])
  cs_result <- chisq.test(contingency_table)
  print("1 day retention Chi-squared test:")
  print(cs_result)
}

# visualizing retention rates
cookie_cats_ret %>%
  group_by(version) %>%
  summarise(
    "1 Day Retention" = mean(one_d_retention),
    "7 Day Retention" = mean(seven_d_retention)
  ) %>%
  ungroup()