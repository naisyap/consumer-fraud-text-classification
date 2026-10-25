# =============================================================
# BBB Scam Tracker Text Mining and Machine Learning Project
# Dataset: BBB Scam Reports
# Categories: phishing, romance, travel
# Purpose:
# This script loads a manually collected dataset of BBB scam reports,
# performs exploratory text analysis, identifies distinctive words using
# TF-IDF, and builds two machine learning classifiers:
# 1. Naive Bayes
# 2. Multinomial Logistic Regression
# =============================================================


# Packages should be installed once in the Console if needed.
# See README.md for installation steps.

# =============================================================
# 2. Load packages
# =============================================================

library(tidyverse)
library(tidytext)
library(stringr)
library(tidymodels)
library(textrecipes)
library(naivebayes)
library(discrim)
library(stopwords)
library(nnet)


# =============================================================
# 3. Set working directory and load data
# =============================================================
# Change this if your folder is somewhere else.
# The CSV file must be inside this folder.

# Run from repository root or within RStudio after setting the working directory
# to the repository root. The full 90-row dataset is not distributed here.
if (!file.exists("data/bbb_scam_reports.csv")) {
  stop("Missing data/bbb_scam_reports.csv. Supply the original 90-report dataset before running.")
}
scams <- read_csv("data/bbb_scam_reports.csv")
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)


# =============================================================
# 4. Inspect the dataset
# =============================================================
# This checks the structure of the dataset and confirms that the
# scam categories are balanced.

glimpse(scams)

scams %>%
  count(scam_type)

scams %>%
  select(id, scam_type, description) %>%
  glimpse()


# =============================================================
# 5. Basic data cleaning
# =============================================================
# This makes sure the scam_type labels are lowercase and removes
# accidental spaces. It also removes rows with missing labels or
# missing descriptions.

scams <- scams %>%
  mutate(
    scam_type = str_to_lower(scam_type),
    scam_type = str_trim(scam_type),
    description = str_squish(description)
  ) %>%
  filter(
    !is.na(scam_type),
    !is.na(description),
    scam_type != "",
    description != ""
  )

# Check category counts again after cleaning
scams %>%
  count(scam_type)


# =============================================================
# 6. Tokenise the text
# =============================================================
# Tokenisation breaks each scam description into individual words.
# Stopwords such as "the", "and", "was", "to" are removed.
# The final filter keeps only alphabetic words.

scam_words <- scams %>%
  unnest_tokens(word, description) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "^[a-z]+$"))

# View the most common words by scam type
scam_words %>%
  count(scam_type, word, sort = TRUE)


# =============================================================
# 7. Most frequent words by scam type
# =============================================================
# This identifies the most common words in each scam category.
# This is useful for exploratory text analysis.

top_words <- scam_words %>%
  count(scam_type, word, sort = TRUE) %>%
  group_by(scam_type) %>%
  slice_max(n, n = 10) %>%
  ungroup()

frequency_plot <- ggplot(top_words, aes(x = reorder(word, n), y = n, fill = scam_type)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ scam_type, scales = "free") +
  coord_flip() +
  labs(
    title = "Most frequent words by scam type",
    x = "Word",
    y = "Frequency"
  )

frequency_plot

# Save the frequency plot
ggsave("figures/frequent_words_by_scam_type.png", frequency_plot, width = 8, height = 5)


# =============================================================
# 8. TF-IDF analysis
# =============================================================
# TF-IDF means Term Frequency-Inverse Document Frequency.
# It identifies words that are especially distinctive to each scam type.
# This is better than simple word frequency because it highlights
# words that are important for distinguishing one category from another.

tfidf_words <- scam_words %>%
  count(scam_type, word, sort = TRUE) %>%
  bind_tf_idf(word, scam_type, n) %>%
  arrange(desc(tf_idf))

tfidf_words

# Save full TF-IDF table
write_csv(tfidf_words, "results/tfidf_words_by_scam_type.csv")


# =============================================================
# 9. Plot top TF-IDF words
# =============================================================

top_tfidf <- tfidf_words %>%
  group_by(scam_type) %>%
  slice_max(tf_idf, n = 10) %>%
  ungroup()

tfidf_plot <- ggplot(top_tfidf, aes(x = reorder(word, tf_idf), y = tf_idf, fill = scam_type)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ scam_type, scales = "free") +
  coord_flip() +
  labs(
    title = "Most distinctive words by scam type using TF-IDF",
    x = "Word",
    y = "TF-IDF"
  )

tfidf_plot

# Save TF-IDF plot
ggsave("figures/tfidf_words_by_scam_type.png", tfidf_plot, width = 8, height = 5)


# =============================================================
# 10. Prepare data for machine learning
# =============================================================
# The target variable is scam_type.
# The predictor variable is description.
# The model will try to predict whether a report is phishing,
# romance, or travel based on the report description.

set.seed(123)

scams <- scams %>%
  mutate(scam_type = as.factor(scam_type))

# Split data into training and testing sets.
# 80% is used for training, 20% for testing.
# strata = scam_type keeps the category balance similar in both sets.

scam_split <- initial_split(scams, prop = 0.8, strata = scam_type)

train_data <- training(scam_split)
test_data <- testing(scam_split)

# Check training and testing category counts
train_data %>%
  count(scam_type)

test_data %>%
  count(scam_type)


# =============================================================
# 11. Create text recipe for modelling
# =============================================================
# This recipe tells R how to process the text before modelling:
# - tokenize text into words
# - remove stopwords
# - keep the top 100 tokens
# - convert words into TF-IDF features

scam_recipe <- recipe(scam_type ~ description, data = train_data) %>%
  step_tokenize(description) %>%
  step_stopwords(description) %>%
  step_tokenfilter(description, max_tokens = 100) %>%
  step_tfidf(description)


# =============================================================
# 12. Model 1: Naive Bayes classifier
# =============================================================
# Naive Bayes is commonly used for text classification.
# It estimates the probability that a report belongs to each scam type
# based on the words in the description.

nb_model <- naive_Bayes() %>%
  set_engine("naivebayes") %>%
  set_mode("classification")

nb_workflow <- workflow() %>%
  add_recipe(scam_recipe) %>%
  add_model(nb_model)

nb_fit <- fit(nb_workflow, data = train_data)

# Predict scam categories for the test data
nb_predictions <- predict(nb_fit, test_data) %>%
  bind_cols(test_data %>% select(scam_type))

nb_predictions

# Evaluate Naive Bayes performance
nb_metrics <- metrics(nb_predictions, truth = scam_type, estimate = .pred_class)
nb_metrics

nb_conf_matrix <- conf_mat(nb_predictions, truth = scam_type, estimate = .pred_class)
nb_conf_matrix

# Save Naive Bayes outputs
write_csv(nb_predictions, "results/naive_bayes_predictions.csv")
write_csv(nb_metrics, "results/naive_bayes_metrics.csv")
write_csv(as.data.frame(nb_conf_matrix$table), "results/naive_bayes_confusion_matrix.csv")


# =============================================================
# 13. Model 2: Multinomial logistic regression
# =============================================================
# Logistic regression is another supervised classification model.
# Because there are three scam categories, this uses multinomial
# logistic regression.

log_reg_model <- multinom_reg() %>%
  set_engine("nnet") %>%
  set_mode("classification")

log_reg_workflow <- workflow() %>%
  add_recipe(scam_recipe) %>%
  add_model(log_reg_model)

log_reg_fit <- fit(log_reg_workflow, data = train_data)

# Predict scam categories for the test data
log_reg_predictions <- predict(log_reg_fit, test_data) %>%
  bind_cols(test_data %>% select(scam_type))

log_reg_predictions

# Evaluate logistic regression performance
log_reg_metrics <- metrics(log_reg_predictions, truth = scam_type, estimate = .pred_class)
log_reg_metrics

log_reg_conf_matrix <- conf_mat(log_reg_predictions, truth = scam_type, estimate = .pred_class)
log_reg_conf_matrix

# Save logistic regression outputs
write_csv(log_reg_predictions, "results/logistic_regression_predictions.csv")
write_csv(log_reg_metrics, "results/logistic_regression_metrics.csv")
write_csv(as.data.frame(log_reg_conf_matrix$table), "results/logistic_regression_confusion_matrix.csv")


# =============================================================
# 14. Compare model performance
# =============================================================
# This table combines the Naive Bayes and Logistic Regression
# results so they can be compared in the report.

model_comparison <- bind_rows(
  nb_metrics %>% mutate(model = "Naive Bayes"),
  log_reg_metrics %>% mutate(model = "Logistic Regression")
) %>%
  select(model, .metric, .estimate)

model_comparison

write_csv(model_comparison, "results/model_comparison.csv")


# =============================================================
# 15. Save cleaned dataset
# =============================================================
# This saves the cleaned version of the dataset used in the analysis.

write_csv(scams, "results/bbb_scam_reports_cleaned.csv")

nb_metrics
log_reg_metrics
model_comparison
nb_conf_matrix
log_reg_conf_matrix
# =============================================================
# 16. End of script
# =============================================================
# Files created:
# - frequent_words_by_scam_type.png
# - tfidf_words_by_scam_type.png
# - tfidf_words_by_scam_type.csv
# - naive_bayes_predictions.csv
# - naive_bayes_metrics.csv
# - naive_bayes_confusion_matrix.csv
# - logistic_regression_predictions.csv
# - logistic_regression_metrics.csv
# - logistic_regression_confusion_matrix.csv
# - model_comparison.csv
# - bbb_scam_reports_cleaned.csv
# =============================================================
