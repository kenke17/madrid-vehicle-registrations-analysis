# Passenger Car Registrations in the Community of Madrid

**Temporal evolution, technological transformation, territorial concentration and market segmentation, 2015–2025**

This repository contains the code, methodology and main results of my Bachelor's Thesis in Applied Statistics at Universidad Complutense de Madrid.

## Project overview

This project analyses passenger car registrations in the Community of Madrid between January 2015 and December 2025 using monthly administrative microdata from the Spanish Directorate-General for Traffic (`Dirección General de Tráfico`, DGT).

After importing, cleaning and filtering the original records, the final analytical dataset contains:

- **3,115,063 valid passenger car registrations**
- **132 monthly periods**
- **11 years of data**
- Technical, environmental, territorial and ownership-related variables

The project combines descriptive statistics, territorial analysis, Factor Analysis of Mixed Data, cluster analysis and time-series analysis.

## Research objectives

The main objective is to study how the passenger car registration market in the Community of Madrid changed between 2015 and 2025.

The analysis focuses on:

- The temporal evolution of registration volumes.
- Changes in propulsion technologies.
- The development of hybrid and electric vehicles.
- The evolution of vehicle power, engine displacement and CO2 emissions.
- Territorial concentration across municipalities.
- The role of legal entities, corporate fleets and renting.
- The identification of differentiated market segments.
- Monthly trend, seasonality and the disruption observed in 2020.

## Data source and processing

The project uses monthly registration microdata provided by the DGT.

The original files:

- Are distributed as fixed-width text files.
- Contain a layout of 69 fields.
- Are imported using `readr::read_fwf()`.
- Require cleaning of missing values, dates, numerical variables and categorical codes.
- Are filtered to retain valid new passenger car registrations in the Community of Madrid.

The original raw files are not included in this repository because of their size and because they remain subject to the conditions established by their official provider.

More information is available in [`data/README.md`](data/README.md).

## Analytical workflow

```text
Monthly DGT fixed-width files
            ↓
Import and data-type conversion
            ↓
Cleaning and validation
            ↓
Selection of valid passenger car registrations
            ↓
Master analytical dataset
            ↓
Descriptive and territorial analysis
            ↓
Factor Analysis of Mixed Data
            ↓
K-means cluster analysis
            ↓
Monthly time-series analysis
            ↓
Interpretation and visual communication
```

## Methods

The project applies the following methods:

- Data cleaning and quality validation.
- Descriptive statistics.
- Monthly and annual aggregation.
- Territorial analysis by municipality.
- Analysis of propulsion technologies.
- Factor Analysis of Mixed Data (`FAMD`).
- K-means clustering on factorial coordinates.
- Cluster profiling and temporal evolution.
- Time-series decomposition using STL.
- Trend and seasonality analysis.
- Statistical data visualisation with R.

## Main findings

### Growth and disruption

Annual registrations increased from **224,111 in 2015** to **351,637 in 2025**, the highest value in the study period.

This growth was interrupted in 2020, when registrations fell by **18.05%** compared with 2019. Recovery became clearer from 2022 onwards.

### Technological transformation

The market changed substantially during the study period:

| Propulsion technology | 2015 | 2025 |
|---|---:|---:|
| Diesel | 74.74% | 10.56% |
| Petrol | 24.11% | 19.43% |
| Hybrid | 0.86% | 60.77% |
| Electric | 0.29% | 9.24% |

Hybrid passenger cars became the dominant category, while diesel registrations lost most of their initial market share.

### Territorial concentration

Registrations are highly concentrated in a limited number of municipalities.

Some municipalities record volumes that are unusually high relative to their resident population. These patterns are strongly associated with:

- Legal ownership.
- Corporate fleets.
- Renting activity.
- Administrative registration practices.
- Possible municipal taxation differences.

Alcobendas is a particularly relevant example because of its high concentration of legal-entity and renting registrations.

### Market segmentation

Factor Analysis of Mixed Data and K-means clustering identified five market profiles:

1. Business-oriented hybrid vehicles.
2. Conventional company and renting vehicles.
3. Higher-power and higher-displacement vehicles.
4. Conventional privately owned vehicles.
5. Electric vehicles.

These profiles reveal that the market is differentiated not only by technical characteristics, but also by ownership and renting status.

### Monthly structure

The monthly series shows:

- A long-term upward trend.
- An exceptional disruption in 2020.
- A gradual recovery after the pandemic.
- Lower registration activity in August.
- Higher activity in months such as December, June, July and November.

## Selected visual results

The following figures are generated reproducibly from the aggregated public
results stored in [`data/public/`](data/public/). They do not require access to
the original DGT microdata.

### Registration evolution

![Annual passenger car registrations in the Community of Madrid](figures/annual_registrations.png)

The annual series shows the interruption associated with 2020 and the subsequent
recovery of passenger car registrations.

![Monthly passenger car registrations in the Community of Madrid](figures/monthly_registrations.png)

The monthly series reveals the short-term disruption, the recovery path and the
recurring seasonal pattern across the 2015–2025 period.

### Propulsion transition

![Evolution of propulsion technologies](figures/propulsion_evolution.png)

The propulsion mix changes substantially over the study period, with a decline
in conventional diesel registrations and increasing relevance of hybrid and
electric technologies.

### Territorial concentration

![Municipal registration ranking](figures/municipal_ranking.png)

Registrations are highly concentrated in a limited number of municipalities,
including locations associated with corporate fleets, renting activity and
atypical registration patterns.

### Multivariate structure

![FAMD explained inertia](figures/famd_inertia.png)

The first three FAMD dimensions explain approximately 64.8% of the total
inertia and are used as input for the final K-means solution.

![Final cluster profiles](figures/cluster_profiles.png)

The five-cluster solution distinguishes hybrid business-oriented vehicles,
company and renting vehicles, higher-power vehicles, privately owned
conventional vehicles and electric vehicles.

All reproducible public figures are available in the
[`figures/`](figures/) directory.

## Repository structure

```text
madrid-vehicle-registrations-analysis/
├── R/
│   ├── 00_configuration.R
│   ├── 01_import_fixed_width_data.R
│   ├── 02_clean_and_filter_data.R
│   ├── 03_descriptive_analysis.R
│   ├── 04_territorial_analysis.R
│   ├── 05_famd_analysis.R
│   ├── 06_cluster_analysis.R
│   ├── 07_time_series_analysis.R
│   └── 99_run_project.R
├── data/
│   ├── raw/
│   ├── processed/
│   ├── sample/
│   └── external/
├── docs/
├── figures/
├── notebooks/
└── reports/
```

## Running the project

The analytical workflow is controlled through:

```r
source("R/99_run_project.R")
```

Calling the project runner without specifying a stage is safe:

```r
run_project()
```

This only displays the execution plan and does not run any analysis.

A single analytical stage can be executed with:

```r
run_project(
  stages = "descriptive"
)
```

Available stages are:

```text
descriptive
territorial
famd
cluster
time_series
```

FAMD and clustering can be executed sequentially with:

```r
run_project(
  stages = c(
    "famd",
    "cluster"
  )
)
```

All analytical stages can be requested with:

```r
run_project(
  stages = "all"
)
```

The complete workflow requires the processed master dataset in the local
`data/processed/` directory. This dataset is not included in the repository.


## Documentation

- [Project overview](docs/project_overview.md)
- [Methodology](docs/methodology.md)
- [Data dictionary](docs/data_dictionary.md)
- [Results](docs/results.md)
- [Data documentation](data/README.md)´
- [Executive summary](reports/executive_summary.md)

These documents are currently being revised to match the final version of the Bachelor's Thesis.

## Technologies

- R
- RStudio
- Quarto
- `dplyr`
- `readr`
- `ggplot2`
- `FactoMineR`
- `cluster`
- Git and GitHub

## Reproducibility

The public repository is organised into documented and reusable scripts.

The project:

- Uses relative paths throughout the analytical workflow.
- Keeps raw and processed large datasets outside version control.
- Separates data preparation from statistical analysis.
- Centralises paths, parameters and dependencies in `R/00_configuration.R`.
- Uses fixed random seeds for reproducible cluster solutions.
- Provides a safe execution controller in `R/99_run_project.R`.
- Stores generated analytical outputs locally.

The main reference values are:

- Analysis period: January 2015 to December 2025.
- Number of monthly observations: 132.
- Final master dataset: 3,115,063 registrations.
- FAMD analytical sample: 3,041,569 complete observations.
- Final cluster solution: five clusters.

Results may still vary slightly depending on the installed R version, package
versions and numerical libraries.

## Limitations

This project analyses new passenger car registrations rather than the complete vehicle fleet.

The municipality recorded in the data corresponds to the administrative location of the vehicle and does not necessarily represent its actual place of use.

The observed associations between municipality, renting, legal ownership and registration volume are descriptive and should not be interpreted automatically as causal relationships.

## Author

**Miguel Moscardó**

Bachelor's Degree in Applied Statistics  
Universidad Complutense de Madrid

## Licensing

The source code is available under the [MIT License](LICENSE).

Written content, reports and original visualisations are subject to the conditions described in [`CONTENT_LICENSE.md`](CONTENT_LICENSE.md).

The original DGT data are not covered by these licenses.