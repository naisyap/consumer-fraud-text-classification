# =============================================================
# Install packages
# =============================================================

# =============================================================
# Load packages
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
# Set working directory and load data
# =============================================================

# Locate the repository root when sourced from RStudio or run with Rscript.
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  for (frame in rev(sys.frames())) {
    if (!is.null(frame$ofile)) return(dirname(normalizePath(frame$ofile)))
  }
  # When running manually, set the working directory to the repository root.
  return(file.path(getwd(), "scripts"))
}
repo_dir <- dirname(get_script_dir())
data_dir <- file.path(repo_dir, "data")
results_dir <- file.path(repo_dir, "results")
figures_dir <- file.path(repo_dir, "figures")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)
if (!file.exists(file.path(data_dir, "bbb_scam_reports.csv"))) {
  stop("Missing data/bbb_scam_reports.csv. See README for private local data setup.")
}

scams <- read_csv(file.path(data_dir, "bbb_scam_reports.csv"))

# =============================================================
# Inspect the dataset
# =============================================================

glimpse(scams)

scams %>%
  count(scam_type)

scams %>%
  select(id, scam_type, description) %>%
  glimpse()

# =============================================================
# Basic data cleaning
# =============================================================

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

scams %>%
  count(scam_type)

# =============================================================
# Tokenise the text
# =============================================================

scam_words <- scams %>%
  unnest_tokens(word, description) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "^[a-z]+$"))

scam_words %>%
  count(scam_type, word, sort = TRUE)

# =============================================================
# Most frequent words by scam type
# =============================================================

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

ggsave(file.path(figures_dir, "frequent_words_by_scam_type.png"), frequency_plot, width = 8, height = 5)

# =============================================================
# TF-IDF analysis
# =============================================================

tfidf_words <- scam_words %>%
  count(scam_type, word, sort = TRUE) %>%
  bind_tf_idf(word, scam_type, n) %>%
  arrange(desc(tf_idf))

tfidf_words

write_csv(tfidf_words, file.path(results_dir, "tfidf_words_by_scam_type.csv"))

# =============================================================
# Plot top TF-IDF words
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

ggsave(file.path(figures_dir, "tfidf_words_by_scam_type.png"), tfidf_plot, width = 8, height = 5)

# =============================================================
# Prepare data for machine learning
# =============================================================

set.seed(123)

scams <- scams %>%
  mutate(scam_type = as.factor(scam_type))

scam_split <- initial_split(scams, prop = 0.8, strata = scam_type)

train_data <- training(scam_split)
test_data <- testing(scam_split)

train_data %>%
  count(scam_type)

test_data %>%
  count(scam_type)

# =============================================================
# Create text recipe for modelling
# =============================================================

scam_recipe <- recipe(scam_type ~ description, data = train_data) %>%
  step_tokenize(description) %>%
  step_stopwords(description) %>%
  step_tokenfilter(description, max_tokens = 100) %>%
  step_tfidf(description)

# =============================================================
# Model 1: Naive Bayes classifier
# =============================================================

nb_model <- naive_Bayes() %>%
  set_engine("naivebayes") %>%
  set_mode("classification")

nb_workflow <- workflow() %>%
  add_recipe(scam_recipe) %>%
  add_model(nb_model)

nb_fit <- fit(nb_workflow, data = train_data)

nb_predictions <- predict(nb_fit, test_data) %>%
  bind_cols(test_data %>% select(scam_type))

nb_predictions

nb_metrics <- metrics(nb_predictions, truth = scam_type, estimate = .pred_class)
nb_metrics

nb_conf_matrix <- conf_mat(nb_predictions, truth = scam_type, estimate = .pred_class)
nb_conf_matrix

write_csv(nb_predictions, file.path(results_dir, "naive_bayes_predictions.csv"))
write_csv(nb_metrics, file.path(results_dir, "naive_bayes_metrics.csv"))
write_csv(as.data.frame(nb_conf_matrix$table), file.path(results_dir, "naive_bayes_confusion_matrix.csv"))

# =============================================================
# Model 2: Multinomial logistic regression
# =============================================================

log_reg_model <- multinom_reg() %>%
  set_engine("nnet") %>%
  set_mode("classification")

log_reg_workflow <- workflow() %>%
  add_recipe(scam_recipe) %>%
  add_model(log_reg_model)

log_reg_fit <- fit(log_reg_workflow, data = train_data)

log_reg_predictions <- predict(log_reg_fit, test_data) %>%
  bind_cols(test_data %>% select(scam_type))

log_reg_predictions

log_reg_metrics <- metrics(log_reg_predictions, truth = scam_type, estimate = .pred_class)
log_reg_metrics

log_reg_conf_matrix <- conf_mat(log_reg_predictions, truth = scam_type, estimate = .pred_class)
log_reg_conf_matrix

write_csv(log_reg_predictions, file.path(results_dir, "logistic_regression_predictions.csv"))
write_csv(log_reg_metrics, file.path(results_dir, "logistic_regression_metrics.csv"))
write_csv(as.data.frame(log_reg_conf_matrix$table), file.path(results_dir, "logistic_regression_confusion_matrix.csv"))

# =============================================================
# Compare model performance
# =============================================================

model_comparison <- bind_rows(
  nb_metrics %>% mutate(model = "Naive Bayes"),
  log_reg_metrics %>% mutate(model = "Logistic Regression")
) %>%
  select(model, .metric, .estimate)

model_comparison

write_csv(model_comparison, file.path(results_dir, "model_comparison.csv"))

# =============================================================
# Save cleaned dataset
# =============================================================

write_csv(scams, file.path(data_dir, "bbb_scam_reports_cleaned.csv"))

nb_metrics
log_reg_metrics
model_comparison
nb_conf_matrix
log_reg_conf_matrix
