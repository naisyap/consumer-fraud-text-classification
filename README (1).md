# Classifying Online Scam Reports Using Text Mining and Machine Learning

**MSc Data Science coursework | University College London | 2026**

## Overview

This project examines whether scam narratives can be classified into phishing, romance and travel fraud categories. The original study used **90 manually coded scam narratives (30 per category)**, and compared Naive Bayes with multinomial logistic regression using R and TF-IDF text features.

This portfolio repository contains the analysis script, previously exported aggregate/model results and two visualisations. **The original individual scam narratives are not published** because they may contain identifying information and require a source-permissions review.

## Methods

- Standardised report descriptions and scam categories, then tokenised text and removed stopwords.
- Compared frequent words and category-specific TF-IDF vocabulary.
- Used a stratified **80/20 training/test split** and TF-IDF features in supervised classification.
- Evaluated Naive Bayes and multinomial logistic regression using accuracy, Cohen's kappa and confusion matrices.

## Results reported by the original project

| Model | Test accuracy | Cohen's kappa |
|---|---:|---:|
| Naive Bayes | 0.333 | 0.000 |
| Multinomial logistic regression | 0.778 | 0.667 |

These are **previously generated coursework results**. The repository script has been reorganised for portability, but the updated version has **not yet been rerun and independently validated** against the original 90-row dataset.

## Visualisations

![Most frequent words by scam type](figures/frequent_words_by_scam_type.png)

![Most distinctive terms by scam type using TF-IDF](figures/tfidf_words_by_scam_type.png)

The word *victim* appears frequently across categories, reflecting the common reporting style rather than a unique fraud mechanism. TF-IDF better highlights distinct terms, such as *dating* and *trust* for romance, *booking* and *hotel* for travel, and *warranty* and *mortgage* for phishing.

## Contents

- `scripts/bbb_scam_analysis.R` — original analytical workflow with package installation removed and portable paths added.
- `results/` — previous model metrics, predictions, confusion matrices and TF-IDF word scores.
- `figures/` — plots produced for the original analysis.
- `data/README.md` — local dataset instructions. Individual report data is excluded from Git.

## Reproducing the analysis locally

1. Install R and, once, required packages:
   ```r
   install.packages(c("tidyverse", "tidytext", "stringr", "tidymodels", "textrecipes", "naivebayes", "discrim", "stopwords", "nnet"))
   ```
2. Put the privately held original dataset at `data/bbb_scam_reports.csv`.
3. In RStudio, open `scripts/bbb_scam_analysis.R` and use **Source**, or from the repository root run:
   ```bash
   Rscript scripts/bbb_scam_analysis.R
   ```
4. Outputs are saved under `results/` and `figures/`; the cleaned individual-level dataset stays under the ignored `data/` directory.
5. Compare new metrics against the committed output files before claiming exact reproducibility.

**Dataset label note:** The original CSV spells the phishing class `Phishing` (cleaned to `phishing`). That spelling is preserved for consistency with the existing exported model results; it is displayed as *phishing* in the narrative description.

## Limitations

The sample is small, balanced by design and manually labelled; results may not generalise to new reports. Fraud descriptions can mix categories, and the test set is small. Performance metrics should not be interpreted as estimates of real-world scam detection effectiveness.

*Academic portfolio project; based on UCL coursework, not the full assessment submission.*
