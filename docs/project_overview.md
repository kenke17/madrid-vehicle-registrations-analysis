# Project Overview

## Vehicle Registrations in Madrid

This project analyses vehicle registration patterns in the Community of Madrid between 2014 and 2025 using administrative microdata from the Spanish Directorate-General for Traffic (`Dirección General de Tráfico`, DGT).

The analysis was developed as a Bachelor's Thesis in Applied Statistics at Universidad Complutense de Madrid.

## Background

Vehicle registration data provide information about changes in mobility, vehicle technologies, environmental performance and territorial patterns.

However, the number of registrations recorded in a municipality does not always represent the number of vehicles actually used by its residents. Corporate fleets, vehicle renting companies and differences in municipal taxation can produce unusually high registration volumes in specific locations.

For this reason, the project combines descriptive, territorial and multivariate techniques to identify both general trends and exceptional municipal patterns.

## Main objective

The main objective is to analyse the evolution, characteristics and territorial distribution of vehicle registrations in the Community of Madrid between 2014 and 2025.

## Specific objectives

The project aims to:

- Describe the main characteristics of registered vehicles.
- Analyse the evolution of registrations over time.
- Compare Madrid city with the surrounding municipalities.
- Study differences in propulsion technology and environmental characteristics.
- Identify municipalities with unusually high registration volumes.
- Examine the role of renting and corporate vehicle registrations.
- Reduce the dimensionality of mixed numerical and categorical data.
- Identify vehicle or territorial profiles through cluster analysis.
- Communicate the results through reproducible statistical analysis and data visualisation.

## Data scope

The cleaned working dataset contains approximately five million observations.

The final variables include information related to:

- Registration date.
- Municipality.
- Vehicle brand and model.
- Vehicle category and type.
- Propulsion technology.
- Engine displacement.
- Engine power.
- Vehicle weight.
- CO2 emissions.
- European emission standard.
- Renting status.
- Body type.
- Electric vehicle range.
- Energy consumption.

## Geographic scope

The analysis focuses on municipalities within the Community of Madrid.

A central territorial comparison distinguishes between:

- **Madrid city:** registrations associated with the municipality of Madrid.
- **Surrounding municipalities:** registrations associated with the remaining municipalities in the region.

This classification supports the analysis of differences between the regional capital and the rest of the Community of Madrid.

## Analytical approach

The project follows several complementary stages:

1. Data import and integration.
2. Data cleaning and validation.
3. Exploratory data analysis.
4. Territorial analysis by municipality.
5. Analysis of propulsion and environmental characteristics.
6. Multiple Correspondence Analysis or Factor Analysis of Mixed Data.
7. Cluster analysis and profile interpretation.
8. Analysis of temporal evolution.
9. Visual communication of the main findings.

## Relevant territorial patterns

Initial exploratory analysis reveals unusually high registration volumes in several municipalities.

These patterns require careful interpretation because they may be influenced by:

- Corporate vehicle fleets.
- Renting companies.
- Municipal vehicle taxation.
- Administrative registration practices.
- Differences between the place of registration and the place of actual use.

Alcobendas is particularly relevant due to the concentration of renting and corporate activity.

Other municipalities also display registration volumes that are unusually high relative to their resident population, making them important cases for the territorial analysis.

## Statistical methods

The project includes:

- Descriptive statistics.
- Data-quality validation.
- Cross-tabulation and grouped summaries.
- Territorial comparisons.
- Analysis of mixed numerical and categorical variables.
- Multiple Correspondence Analysis.
- Factor Analysis of Mixed Data.
- Unsupervised clustering.
- Cluster profiling.
- Temporal aggregation and trend analysis.
- Statistical and geographic visualisation.

## Tools

The analysis is primarily developed using:

- R.
- RStudio.
- Quarto or R Markdown.
- Git and GitHub.
- Reproducible scripts and documented transformations.

## Expected outputs

The repository will include:

- Documented R scripts.
- A data dictionary.
- Methodological documentation.
- Small reproducible data samples.
- Aggregated results.
- Final visualisations.
- An executive summary.
- The main findings of the Bachelor's Thesis.

## Author

**Miguel Moscardó**

Bachelor's Degree in Applied Statistics  
Universidad Complutense de Madrid