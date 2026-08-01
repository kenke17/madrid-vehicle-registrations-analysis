# Results

This document summarises the main findings of the project.

The results are currently under development and will be updated after the final validation of the descriptive, territorial, multivariate and temporal analyses.

## 1. Dataset overview

After the initial integration, filtering and cleaning stages, the working dataset contains approximately five million vehicle registration records from the Community of Madrid between 2014 and 2025.

The analytical dataset includes information about:

- Registration date.
- Municipality.
- Vehicle type.
- Brand and model.
- Propulsion technology.
- Engine characteristics.
- Vehicle weight.
- CO2 emissions.
- European emission standard.
- Renting status.
- Electric range and energy consumption.

Final observation counts will be added after the complete validation of all filtering rules.

## 2. Territorial concentration

The exploratory analysis shows that vehicle registrations are highly concentrated in a limited number of municipalities.

Madrid city is not necessarily the municipality with the highest number of registered vehicles, despite being the largest municipality in the region.

Several municipalities display registration volumes that are unusually high in relation to their resident population.

These patterns suggest that registration totals cannot be interpreted exclusively as indicators of local vehicle ownership or local mobility demand.

## 3. Municipalities with atypical registration volumes

The preliminary territorial analysis identifies several municipalities with particularly high registration totals.

Relevant cases include:

- Alcobendas.
- Robledo de Chavela.
- Moralzarzal.
- Rozas de Puerto Real.
- Venturada.
- Colmenar del Arroyo.
- Navacerrada.

These municipalities require separate interpretation because their registration volumes may be influenced by administrative, corporate or fiscal factors.

The final analysis will compare:

- Absolute registration totals.
- Population-adjusted indicators, when suitable population data are available.
- Renting concentration.
- Vehicle-type composition.
- Propulsion composition.
- Evolution over time.

## 4. Renting and corporate registrations

Alcobendas shows a particularly strong concentration of vehicles associated with renting activity.

This pattern is consistent with the presence of companies and corporate fleets whose vehicles may be registered in the municipality but used throughout the region or across Spain.

As a result, registrations recorded in Alcobendas should not be interpreted as a direct measure of the number of vehicles used by local residents.

The renting variable will be analysed by:

- Municipality.
- Year.
- Vehicle type.
- Propulsion technology.
- Brand and model.
- Madrid city versus surrounding municipalities.

## 5. Fiscal and administrative effects

Some municipalities appear to have registration volumes that are disproportionate to their population size.

A possible explanation is the existence of municipal tax differences or administrative practices that make certain municipalities attractive for registering large vehicle fleets.

This hypothesis must be treated carefully.

The registration data alone do not establish a causal relationship between taxation and registration volume. Additional municipal, fiscal or corporate information would be required to confirm the mechanism.

The final interpretation will therefore distinguish between:

- Patterns directly observed in the data.
- Plausible explanations supported by external information.
- Hypotheses that cannot be confirmed using the registration dataset alone.

## 6. Madrid city versus surrounding municipalities

The project compares Madrid city with the remaining municipalities in the Community of Madrid.

This comparison is designed to examine differences in:

- Total registration volume.
- Propulsion technologies.
- Vehicle types.
- Renting activity.
- Environmental characteristics.
- Vehicle power and weight.
- Temporal evolution.

The classification is defined as:

```text
Madrid city:
municipio_df == "Madrid"

Surrounding municipalities:
municipio_df != "Madrid"
```

Final comparative tables and visualisations will be added after validation.

## 7. Propulsion technologies

The temporal analysis will examine the transition between:

- Petrol vehicles.
- Diesel vehicles.
- Hybrid vehicles.
- Plug-in hybrid vehicles.
- Battery-electric vehicles.
- Other propulsion technologies.

The main objectives are to determine:

- How the distribution of propulsion technologies has changed since 2014.
- Whether the transition differs between municipalities.
- Whether renting vehicles show a different technological composition.
- Whether Madrid city differs from the surrounding municipalities.
- How vehicle emissions and electric range have evolved.

Final percentages and growth rates are pending validation.

## 8. Environmental characteristics

The project analyses environmental variables including:

- CO2 emissions.
- European emission standards.
- Electric energy consumption.
- Electric driving range.
- Propulsion technology.

These variables will be used to describe the environmental transformation of newly registered vehicles.

The interpretation must account for missing and non-applicable values, particularly for variables that are only relevant to electric or combustion vehicles.

## 9. Multivariate analysis

The multivariate stage will use Multiple Correspondence Analysis or Factor Analysis of Mixed Data, depending on the selected variables.

The objectives are to:

- Identify the main dimensions of variation.
- Detect associations between vehicle characteristics.
- Reduce the dimensionality of the dataset.
- Construct a suitable representation for cluster analysis.
- Interpret technological and structural vehicle profiles.

The final dimensional solution will be documented with:

- Explained inertia or variance.
- Variable contributions.
- Category coordinates.
- Factor maps.
- Interpretation of the main dimensions.

## 10. Cluster analysis

Cluster analysis will be used to identify groups with similar characteristics.

Depending on the final analytical design, clusters may represent:

- Vehicle profiles.
- Municipal profiles.
- Technological segments.
- Territorial registration patterns.

Each cluster will be described using the original variables rather than only the reduced-dimensional coordinates.

The final results will include:

- Selected number of clusters.
- Statistical justification.
- Cluster sizes.
- Main characteristics.
- Descriptive labels.
- Visual comparisons.
- Interpretation and limitations.

## 11. Temporal evolution

The analysis will describe the evolution of registrations between 2014 and 2025.

The main temporal outputs will include:

- Annual registration totals.
- Monthly or quarterly trends when appropriate.
- Changes in propulsion technology.
- Evolution of renting activity.
- Evolution of vehicle emissions.
- Changes in municipal concentration.
- Evolution of the profiles identified through clustering.

The final analysis will distinguish long-term structural changes from short-term fluctuations.

## 12. Main preliminary conclusions

The preliminary analysis supports the following conclusions:

1. Vehicle registrations are strongly concentrated in a limited number of municipalities.
2. Registration municipality does not necessarily represent the place where the vehicle is used.
3. Renting and corporate fleets substantially affect the territorial distribution of registrations.
4. Alcobendas is a particularly relevant case because of its concentration of renting activity.
5. Several small municipalities show unusually high registration totals and require separate interpretation.
6. Territorial comparisons must consider administrative and fiscal factors.
7. The transition towards alternative propulsion technologies should be analysed jointly with municipality and renting status.

These conclusions remain subject to the final validation of the complete analytical workflow.

## 13. Pending results

The following elements will be added before the final public release:

- Final dataset size.
- Validated municipal ranking.
- Madrid city versus surrounding municipalities comparison.
- Propulsion-technology trends.
- Renting distribution.
- CO2 emission trends.
- MCA or FAMD results.
- Cluster profiles.
- Temporal-analysis results.
- Publication-ready figures.
- Executive summary of the main findings.

## 14. Interpretation principles

All results will follow these principles:

- Descriptive associations will not be presented as causal effects.
- Large registration totals will not automatically be interpreted as local vehicle ownership.
- Missing and non-applicable values will be reported clearly.
- External explanations will be distinguished from direct evidence contained in the dataset.
- Unusual observations will be investigated before being removed.
- Statistical significance will be considered alongside practical relevance.