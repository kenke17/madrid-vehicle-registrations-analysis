# Project Overview

## Passenger Car Registrations in the Community of Madrid

This project analyses the evolution and structure of new passenger car registrations in the Community of Madrid between January 2015 and December 2025.

It was developed as a Bachelor's Thesis in Applied Statistics at Universidad Complutense de Madrid.

## Project scope

The analysis is based on monthly administrative microdata published by the Spanish Directorate-General for Traffic (`Dirección General de Tráfico`, DGT).

After importing, cleaning and filtering the original records, the final analytical dataset contains:

- **3,115,063 valid passenger car registrations**
- **132 monthly periods**
- **11 complete years of analysis**
- Technical, environmental, territorial and ownership-related variables

The project studies registered passenger cars rather than the complete vehicle fleet currently in circulation.

## Motivation

The passenger car market experienced major changes during the study period.

These changes include:

- The decline of diesel registrations.
- The expansion of hybrid and electric technologies.
- Changes in vehicle power, engine displacement and emissions.
- The disruption caused by the events of 2020.
- The growing importance of renting and corporate fleets.
- Strong territorial concentration in a limited number of municipalities.

Administrative registration data provide a detailed source for analysing these transformations. However, they also require careful interpretation because the municipality of registration does not necessarily correspond to the place where a vehicle is used.

## Main objective

The main objective is to analyse the temporal, technological and territorial transformation of new passenger car registrations in the Community of Madrid between 2015 and 2025.

## Specific objectives

The project aims to:

- Describe the evolution of monthly and annual registration volumes.
- Analyse changes in propulsion technologies.
- Study the evolution of technical and environmental vehicle characteristics.
- Compare registration patterns across municipalities.
- Examine the concentration of legal entities, renting and corporate fleets.
- Identify municipalities with atypical registration volumes.
- Reduce the dimensionality of mixed numerical and categorical data.
- Identify differentiated market profiles through cluster analysis.
- Study the trend and seasonal structure of the monthly registration series.
- Communicate the results through reproducible statistical analysis and visualisation.

## Data source

The original DGT data are distributed as monthly fixed-width text files.

The data-import process uses:

- A layout containing 69 fields.
- Explicit fixed-width positions.
- `readr::read_fwf()`.
- Text cleaning and missing-value treatment.
- Date and numerical conversion.
- Validation of categorical codes.
- Integration of the monthly files into a master dataset.

The original files are not published in this repository because of their size and because they remain subject to the conditions established by the official provider.

## Analytical sample

The final sample is restricted to valid new passenger car registrations associated with the Community of Madrid.

The preparation process includes:

- Geographic selection.
- Filtering by vehicle class and type.
- Selection of new registrations.
- Exclusion of administrative withdrawals and cancellations.
- Removal of records outside the analytical scope.
- Validation of relevant variables.

The complete implementation will be included in the cleaned public scripts.

## Analytical workflow

```text
Monthly DGT fixed-width files
            ↓
Import and integration
            ↓
Cleaning and type conversion
            ↓
Filtering and validation
            ↓
Final passenger car dataset
            ↓
Descriptive analysis
            ↓
Territorial analysis
            ↓
Factor Analysis of Mixed Data
            ↓
K-means clustering
            ↓
Monthly time-series analysis
            ↓
Interpretation and visualisation
```

## Descriptive analysis

The descriptive stage examines:

- Monthly and annual registration totals.
- Propulsion technologies.
- Vehicle power.
- Engine displacement.
- CO2 emissions.
- Ownership type.
- Renting activity.
- Main brands and models.
- Changes observed throughout the study period.

The results are presented using absolute frequencies, relative distributions and temporal visualisations.

## Territorial analysis

The territorial stage studies how registrations are distributed across municipalities in the Community of Madrid.

It examines:

- Total registrations by municipality.
- Evolution over time.
- Concentration of legal entities.
- Renting activity.
- Propulsion composition.
- Differences between Madrid city and the remaining municipalities.
- Municipalities with registration totals that are unusually high relative to their population.

These patterns must be interpreted carefully because large corporate or renting fleets can be registered in one municipality while being used elsewhere.

Alcobendas is a particularly relevant case because of its concentration of legal-entity and renting registrations.

Other municipalities also display atypical volumes that may be related to administrative or fiscal factors. These explanations are treated as contextual hypotheses rather than causal conclusions derived directly from the registration data.

## Factor Analysis of Mixed Data

Factor Analysis of Mixed Data (`FAMD`) is used because the segmentation stage combines numerical and categorical variables.

The final FAMD dataset includes five quantitative variables:

- Engine displacement.
- Engine power.
- Normalised CO2 emissions.
- Electric energy consumption.
- Distance between axles.

It also includes three qualitative variables:

- Propulsion technology.
- Renting status.
- Individual or legal ownership.

CO2 emissions are standardised separately according to the applicable NEDC or WLTP measurement framework.

The factorial analysis is used to:

- Reduce dimensionality.
- Balance numerical and categorical information.
- Identify the main dimensions of vehicle differentiation.
- Generate coordinates for subsequent cluster analysis.

## Cluster analysis

K-means clustering is applied to the factorial coordinates produced by the FAMD.

Alternative cluster solutions are evaluated using:

- The within-cluster sum of squares.
- The silhouette method.
- Cluster size.
- Stability.
- Interpretability of the resulting profiles.

The final solution contains **five clusters**.

These clusters represent:

1. Business-oriented hybrid vehicles.
2. Conventional company and renting vehicles.
3. Higher-power and higher-displacement vehicles.
4. Conventional privately owned vehicles.
5. Electric vehicles.

The profiles are interpreted using the original variables rather than only the factorial coordinates.

## Time-series analysis

The temporal analysis uses a monthly series covering 132 periods.

The analysis includes:

- Monthly registration totals.
- Annual growth and decline.
- Long-term trend.
- Seasonal patterns.
- The disruption observed in 2020.
- Recovery during the following years.
- STL decomposition into trend, seasonal and irregular components.

The purpose of this stage is descriptive. It identifies the internal temporal structure of the series without presenting associations as causal effects.

## Main findings

The project identifies several major transformations:

- Annual registrations increased from 2015 to their highest level in 2025, although the pattern was interrupted in 2020.
- Diesel lost most of its initial market share.
- Hybrid vehicles became the dominant propulsion category by the end of the study period.
- Electric registrations increased, although their share remained below that of hybrid vehicles.
- Registrations are strongly concentrated in a limited number of municipalities.
- Renting and legal ownership have a substantial influence on the territorial distribution.
- Five differentiated technological and ownership-related market profiles were identified.
- The monthly series shows a long-term upward trend, a strong disruption in 2020 and a recurring seasonal structure.

Detailed numerical results are documented in:

```text
docs/results.md
```

## Statistical tools

The project uses:

- R.
- RStudio.
- Quarto.
- `readr`.
- `dplyr`.
- `tidyr`.
- `lubridate`.
- `stringr`.
- `ggplot2`.
- `FactoMineR`.
- `factoextra`.
- `cluster`.
- `purrr`.
- `patchwork`.

## Repository outputs

The public repository will contain:

- Clean and documented R scripts.
- Selected Quarto notebooks.
- A data dictionary.
- Methodological documentation.
- Small reproducible samples or aggregated datasets.
- Publication-ready figures.
- A summary of the main results.
- The final academic report when appropriate.

## Reproducibility

The original analytical code is being reorganised into a public workflow that:

- Uses relative paths.
- Preserves the original source files.
- Separates import, cleaning and analysis.
- Documents relevant decisions.
- Excludes large raw and intermediate datasets.
- Records the required package dependencies.
- Produces reusable aggregated outputs.

## Limitations

The main limitations are:

- Registration location may differ from actual vehicle use.
- Renting and corporate fleets can dominate municipal totals.
- Some technical variables contain missing or non-applicable values.
- Measurement and coding conventions may change over time.
- The data were collected for administrative rather than research purposes.
- Descriptive relationships must not be interpreted automatically as causal effects.
- The analysis covers new passenger car registrations, not the complete vehicle fleet.

## Author

**Miguel Moscardó**

Bachelor's Degree in Applied Statistics  
Universidad Complutense de Madrid