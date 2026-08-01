# Methodology

This document describes the analytical workflow used in the project.

The methodology may be refined as the Bachelor's Thesis reaches its final version. Any methodological change affecting the published results will be documented in this repository.

## 1. Research design

The project follows an observational and exploratory approach based on administrative vehicle registration records.

The analysis combines:

- Data cleaning and validation.
- Descriptive statistics.
- Territorial analysis.
- Multivariate exploratory methods.
- Unsupervised clustering.
- Temporal analysis.
- Statistical visualisation.

The objective is not only to describe registration volumes, but also to identify territorial, technological and structural patterns within the vehicle market of the Community of Madrid.

## 2. Data source

The analysis uses vehicle registration microdata published by the Spanish Directorate-General for Traffic (`Dirección General de Tráfico`, DGT).

The study period covers registrations between 2014 and 2025.

The working dataset contains approximately five million observations after the initial integration and filtering stages.

The original source files are not included in this repository. They must be obtained separately from the official provider and stored in:

```text
data/raw/
```

## 3. Geographic scope

The analysis is restricted to vehicles registered in municipalities belonging to the Community of Madrid.

Municipality names are cleaned and standardised before aggregation.

Two territorial levels are considered:

1. Individual municipalities.
2. A broader comparison between Madrid city and the surrounding municipalities.

The territorial classification is defined as:

- **Madrid city:** `municipio_df == "Madrid"`.
- **Surrounding municipalities:** all remaining municipalities in the Community of Madrid.

This classification is used to study whether registration patterns differ between the regional capital and the rest of the region.

## 4. Vehicle scope

The analytical sample is restricted to the vehicle classes and types relevant to the objectives of the project.

The current cleaning criteria include the following permitted values:

```text
COD_CLASE_MAT ∈ {0, 3, 6, 8}
```

```text
COD_TIPO ∈ {
  0G, 20, 21, 24, 25,
  50, 51, 54,
  90, 91, 92
}
```

Records associated with vehicle withdrawals or administrative cancellations are excluded according to the corresponding source variables.

The exact filtering rules will be implemented and documented in the data-cleaning scripts.

## 5. Data integration

The original annual or periodic source files are imported and combined into a common analytical structure.

The integration process includes:

- Harmonising column names.
- Converting variables to consistent data types.
- Preserving the source period.
- Checking that the same variables have compatible formats across files.
- Identifying duplicated or inconsistent records.
- Validating the number of observations after each transformation.

A derived variable named `periodo` is retained to identify the corresponding source or analytical period.

## 6. Data cleaning

The cleaning process includes the following stages:

### 6.1 Dates

The registration date variable `FEC_MATRICULA` is converted to a valid date format.

Temporal components may be derived from this variable, including:

- Year.
- Month.
- Quarter.
- Analysis period.

### 6.2 Municipalities

Municipality information is cleaned to resolve:

- Differences in uppercase and lowercase letters.
- Leading or trailing spaces.
- Accent and encoding inconsistencies.
- Alternative spellings.
- Formatting differences between source files.

The project retains cleaned variables such as:

- `municipio_df`.
- `municipio_std`.

### 6.3 Categorical variables

Categorical variables are reviewed to identify:

- Missing values.
- Unknown codes.
- Duplicated labels.
- Inconsistent spelling.
- Categories with very low frequency.
- Codes requiring correspondence tables.

Relevant categorical variables include:

- Vehicle brand.
- Vehicle model.
- Vehicle type.
- Propulsion technology.
- Body type.
- Euro emission standard.
- Renting status.

### 6.4 Numerical variables

Numerical variables are converted to appropriate formats and reviewed for:

- Impossible values.
- Extreme observations.
- Missing values.
- Inconsistent measurement scales.
- Variables applicable only to specific vehicle technologies.

Relevant numerical variables include:

- Engine displacement.
- Engine power.
- Vehicle weight.
- CO2 emissions.
- Electric range.
- Electric energy consumption.
- Distance between axles.

Outliers are not removed automatically. Their treatment depends on whether they represent data errors or valid but unusual vehicles.

## 7. Data validation

Validation checks are performed after the main cleaning stages.

These checks include:

- Number of observations before and after filtering.
- Distribution of missing values.
- Frequency tables for categorical variables.
- Summary statistics for numerical variables.
- Verification of municipality totals.
- Validation of renting categories.
- Comparison of totals across years and source files.

Special attention is given to municipalities with unusually high registration volumes.

These values are not assumed to be errors, as they may be associated with:

- Renting companies.
- Corporate vehicle fleets.
- Administrative registration practices.
- Differences in municipal vehicle taxation.
- A mismatch between registration location and actual vehicle use.

## 8. Descriptive analysis

The descriptive stage summarises the main characteristics of the registrations.

The analysis includes:

- Total registrations by year.
- Registrations by municipality.
- Registrations by vehicle type.
- Registrations by propulsion technology.
- Renting distribution.
- Brand and model frequencies.
- Distributions of power, weight and emissions.
- Evolution of electric and hybrid vehicles.
- Missing-data patterns.

Tables and figures are designed to communicate both absolute volumes and relative distributions.

## 9. Territorial analysis

The territorial analysis studies differences between municipalities.

The main outputs may include:

- Municipal registration totals.
- Annual municipal trends.
- Registration rates or normalised indicators when suitable denominator data are available.
- Renting concentration by municipality.
- Propulsion composition by municipality.
- Comparison between Madrid city and surrounding municipalities.
- Identification of atypical municipal profiles.

Municipal results are interpreted carefully because registration totals do not necessarily represent the number of vehicles used by local residents.

Alcobendas is analysed as a particularly relevant case due to the concentration of renting and corporate registrations.

Other municipalities with unusually high totals are examined separately to determine whether their patterns may be associated with taxation or administrative factors.

## 10. Multivariate analysis

The dataset contains both numerical and categorical variables.

For this reason, the project considers multivariate methods adapted to mixed data.

### 10.1 Multiple Correspondence Analysis

Multiple Correspondence Analysis may be used when the selected analytical variables are entirely categorical.

Its purpose is to:

- Reduce the dimensionality of the categorical information.
- Identify associations between categories.
- Visualise vehicle or territorial profiles.
- Generate coordinates suitable for subsequent clustering.

### 10.2 Factor Analysis of Mixed Data

Factor Analysis of Mixed Data may be used when numerical and categorical variables are analysed jointly.

Its purpose is to:

- Balance the contribution of numerical and categorical information.
- Identify the main dimensions of variation.
- Reduce redundancy between variables.
- Create a lower-dimensional representation for cluster analysis.

The final choice between MCA and FAMD depends on the variables included in each analytical dataset.

## 11. Cluster analysis

Cluster analysis is used to identify groups of observations with similar characteristics.

Depending on the analytical level, clustering may be applied to:

- Individual vehicle registrations.
- Aggregated vehicle profiles.
- Municipal indicators.
- Coordinates obtained from MCA or FAMD.

The clustering workflow includes:

1. Selecting the analytical variables.
2. Treating missing values.
3. Reducing dimensionality when necessary.
4. Comparing different numbers of clusters.
5. Evaluating cluster stability and interpretability.
6. Profiling each cluster using the original variables.
7. Assigning descriptive names only after examining the results.

The number of clusters is not selected solely from a statistical criterion. Interpretability and usefulness for the research objectives are also considered.

## 12. Temporal analysis

The temporal stage examines how registration patterns evolve between 2014 and 2025.

The analysis may include:

- Annual and monthly registration totals.
- Growth rates.
- Changes in propulsion technologies.
- Evolution of environmental characteristics.
- Changes in renting activity.
- Trends by municipality or territorial group.
- Evolution of the profiles identified through clustering.

Time-series models will only be applied when the frequency, completeness and statistical properties of the aggregated series justify their use.

## 13. Visualisation

Visualisations are created to make the main findings understandable to both technical and non-technical audiences.

The planned outputs include:

- Time-series charts.
- Municipal rankings.
- Territorial maps.
- Propulsion-composition charts.
- Madrid city versus surrounding municipalities comparisons.
- Factor maps from MCA or FAMD.
- Cluster-profile charts.
- Missing-data summaries.

Final figures will be stored in:

```text
figures/
```

Only reviewed and publication-ready figures will be included in the public repository.

## 14. Reproducibility

The analysis is organised into separate scripts according to their purpose.

The planned script structure is:

```text
R/
├── 00_configuration.R
├── 01_data_import.R
├── 02_data_cleaning.R
├── 03_descriptive_analysis.R
├── 04_territorial_analysis.R
├── 05_multivariate_analysis.R
├── 06_clustering.R
├── 07_temporal_analysis.R
└── 08_final_visualisations.R
```

The final filenames may be adapted to the actual workflow.

Each script should:

- Have a clearly defined purpose.
- Avoid unnecessary duplication.
- Use relative file paths.
- Document important transformations.
- Produce reproducible outputs.
- Avoid modifying the original source files.

## 15. Limitations

The main methodological limitations include:

- Registration municipality may differ from the place of actual vehicle use.
- Corporate and renting fleets may dominate the totals of some municipalities.
- Some technical variables contain missing or non-applicable values.
- Coding conventions may change between source periods.
- Administrative data were not originally collected specifically for this research.
- Large sample sizes can make small differences appear statistically important.
- Descriptive associations must not be interpreted automatically as causal relationships.

These limitations will be considered in the interpretation of all results.