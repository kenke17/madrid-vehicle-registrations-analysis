# Vehicle Registrations in Madrid

Statistical and territorial analysis of vehicle registrations in the Community of Madrid between 2014 and 2025.

This repository contains the code, methodology and main results of my Bachelor's Thesis in Applied Statistics at Universidad Complutense de Madrid.

## Project overview

The project analyses approximately five million vehicle registration records obtained from the Spanish Directorate-General for Traffic.

The objective is to study the evolution and territorial distribution of vehicle registrations in the Community of Madrid, paying particular attention to:

- Differences between Madrid city and the surrounding municipalities.
- Changes in propulsion technologies and vehicle characteristics.
- Municipalities with unusually high registration volumes.
- Vehicle and territorial segmentation using multivariate methods.
- Evolution of registration patterns between 2014 and 2025.

## Main methods

- Data cleaning and validation.
- Exploratory data analysis.
- Territorial analysis.
- Multiple Correspondence Analysis and FAMD.
- Cluster analysis.
- Time evolution and trend analysis.
- Data visualisation with R.

## Dataset

The original dataset contains approximately five million observations and includes variables related to:

- Registration date.
- Municipality.
- Vehicle brand and model.
- Vehicle type.
- Propulsion technology.
- Engine power and displacement.
- CO₂ emissions.
- European emission standard.
- Renting status.
- Electric range and energy consumption.

The original raw data are not included in this repository due to their size. Instructions, sample data and aggregated results will be added to allow the analysis to be understood and partially reproduced.

## Repository structure

```text
.
├── R/             # R scripts
├── data/
│   ├── raw/       # Original data, not tracked by Git
│   ├── sample/    # Small reproducible data samples
│   └── processed/ # Aggregated and processed results
├── docs/          # Methodology and documentation
├── figures/       # Final visualisations
├── notebooks/     # Quarto or R Markdown analyses
└── reports/       # Executive summary and final report

```text
## Author

**Miguel Moscardó**
Bachelor's Degree in Applied Statistics
Universidad Complutense de Madrid