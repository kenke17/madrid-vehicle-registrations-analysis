# Data

This directory contains the data resources used in the project.

## Data source

The analysis is based on vehicle registration microdata published by the Spanish Directorate-General for Traffic (`Dirección General de Tráfico`, DGT).

The project focuses on vehicles registered in the Community of Madrid between 2014 and 2025.

## Directory structure

```text
data/
├── raw/        # Original DGT files
├── sample/     # Small reproducible data samples
└── processed/  # Aggregated datasets and analysis outputs
```

## Raw data

The original files are not included in this repository because:

- They contain approximately five million observations.
- Their size exceeds the practical limits of a GitHub repository.
- Users should obtain the original data from the official source.
- Keeping raw data outside Git prevents accidental modifications and unnecessary duplication.

Files placed in `data/raw/` are ignored by Git.

## Processed data

The `processed/` directory may contain small aggregated datasets used to reproduce figures and results, such as:

- Annual registration totals.
- Municipal indicators.
- Propulsion-type distributions.
- Cluster summaries.
- Comparisons between Madrid city and the surrounding municipalities.

## Sample data

A reduced sample may be added to `sample/` so that users can inspect the data structure and test parts of the analysis without downloading the complete dataset.

The sample data will preserve the structure of the original dataset while containing only a limited number of observations.

## Main variables

The cleaned dataset includes variables related to:

- Registration date.
- Municipality.
- Vehicle brand and model.
- Vehicle type.
- Propulsion technology.
- Engine displacement and power.
- Vehicle weight.
- CO2 emissions.
- European emission standard.
- Renting status.
- Electric vehicle range.
- Energy consumption.

A detailed data dictionary will be included in the project documentation.

## Reproducibility

The scripts contained in the `R/` directory will document the complete data-cleaning and transformation process.

To reproduce the analysis, the original source files must be downloaded separately and stored inside:

```text
data/raw/
```

The filenames and required directory structure will be documented when the data-import scripts are added.

## Data usage

The original data remain subject to the terms and conditions established by their official provider.

This repository does not claim ownership of the original DGT data. Only code, documentation, small samples and derived aggregated results will be published.