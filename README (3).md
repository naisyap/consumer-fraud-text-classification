# Classifying Online Scam Reports Using Text Mining and Machine Learning

**MSc Data Science project | University College London | 2026**

## Overview
This project explored whether scam narratives could be classified into **phishing, romance and travel** categories using R-based text mining and supervised machine learning. The dissertation project report describes a manually coded, balanced dataset of **90 scam narratives (30 per class)**.

## Methods
- Standardised scam labels and text descriptions.
- Tokenised narratives, removed stopwords and compared word frequencies.
- Calculated **TF-IDF** to identify vocabulary associated with each scam category.
- Performed a stratified **80/20 training/test split**.
- Compared **Naive Bayes** and **multinomial logistic regression** classifiers based on TF-IDF text features.
- Evaluated models using accuracy, Cohen's kappa and confusion matrices.

## Reported results
The original research report recorded:

| Model | Test accuracy | Cohen's kappa |
|---|---:|---:|
| Naive Bayes | 0.333 | 0.000 |
| Multinomial logistic regression | 0.778 | 0.667 |

These are **reported results**, not newly reproduced results in this repository. Because the sample is small and manually coded, estimates are exploratory and may not generalise to other scam reports.

## Repository layout
- `scripts/bbb_scam_analysis.R` — original analysis workflow with path/installation adjustments for GitHub.
- `data/` — **add the original 90-row CSV locally**, named `bbb_scam_reports.csv`.
- `results/` — generated model metrics and processed outputs after execution.
- `figures/` — generated word-frequency and TF-IDF plots after execution.

## Reproducing the analysis
1. Obtain the original **90-row** source dataset. It is **not included** here. The pilot CSV found among previous files is **not a substitute** for this final dataset.
2. Check scam narratives for personal identifiers and relevant source-data redistribution restrictions before sharing any dataset publicly.
3. Place the final dataset at `data/bbb_scam_reports.csv`.
4. Open RStudio and set the working directory to the **repository root** (not `scripts/`).
5. Install dependencies **once in the Console**, if needed:

```r
install.packages(c("tidyverse", "tidytext", "stringr", "tidymodels", "textrecipes", "naivebayes", "discrim", "stopwords", "nnet"))
```

6. Execute:

```r
source("scripts/bbb_scam_analysis.R")
```

The script writes model metrics to `results/` and plots to `figures/`. It has **not been re-executed or validated** against the 90-row dataset in preparing this portfolio version.

## Limitations
The original dataset comprised manually summarised scam reports. Some categories overlap; the small, balanced sample and manual coding limit external validity. Public crime reports can contain sensitive information, so do not add raw unreviewed narratives to a public repository.

*Academic portfolio project. This repository showcases code and the findings documented in the original UCL project report, rather than the complete assessment submission.*
