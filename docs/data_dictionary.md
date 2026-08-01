# Data Dictionary

This document describes the main variables contained in the cleaned dataset used for the analysis.

The dictionary is based on the current version of the project dataset and will be updated as the data-cleaning process is finalised.

## Variable definitions

| Variable | Data type | Description | Notes |
|---|---|---|---|
| `FEC_MATRICULA` | Date | Vehicle registration date. | Main variable used for temporal analysis. |
| `MARCA_ITV` | Character | Vehicle manufacturer or brand recorded in the technical inspection data. | Categories require standardisation. |
| `MODELO_ITV` | Character | Vehicle model recorded in the technical inspection data. | May contain inconsistent spellings or formats. |
| `COD_TIPO` | Character | Code identifying the vehicle type. | Filtered according to the scope of the analysis. |
| `COD_PROPULSION_ITV` | Character | Code identifying the vehicle propulsion technology. | Used to distinguish combustion, hybrid, electric and other technologies. |
| `CILINDRADA_ITV` | Integer | Engine displacement recorded in the technical inspection data. | Mainly applicable to combustion vehicles. |
| `POTENCIA_ITV` | Double | Engine power recorded in the technical inspection data. | Measurement unit must be verified against the source documentation. |
| `TARA` | Integer | Vehicle unladen weight. | Used as a vehicle-size and weight indicator. |
| `MUNICIPIO` | Character | Original municipality field contained in the source data. | Requires cleaning and standardisation. |
| `CO2_ITV` | Integer | Vehicle CO2 emissions recorded in the technical inspection data. | Mainly used for environmental analysis. |
| `RENTING` | Character | Indicator showing whether the vehicle is associated with renting activity. | Values include `S`, `N` and missing records. |
| `CARROCERIA` | Character | Vehicle body-type classification. | Used as a categorical vehicle characteristic. |
| `NIVEL_EMISIONES_EURO_ITV` | Character | European vehicle-emission standard. | Categories may include different Euro standards. |
| `CONSUMO_WH_KM_ITV` | Double | Electric energy consumption recorded for the vehicle. | Mainly applicable to electric vehicles. |
| `AUTONOMIA_VEHICULO_ELECTRICO` | Numeric | Reported electric driving range. | Mainly applicable to electric and plug-in hybrid vehicles. |
| `DISTANCIA_EJES_12_ITV` | Numeric | Distance between the first and second vehicle axles. | Used as a structural vehicle characteristic. |
| `periodo` | Numeric | Analysis period derived for temporal aggregation. | Definition will be documented in the transformation scripts. |
| `municipio_df` | Character | Cleaned municipality variable used in the analytical dataset. | Used for municipal aggregation. |
| `municipio_std` | Character | Standardised municipality name. | Created to resolve spelling and formatting inconsistencies. |

## Derived territorial classification

The project uses a territorial classification that separates:

- **Madrid city:** observations where `municipio_df` is equal to `Madrid`.
- **Surrounding municipalities:** observations corresponding to the remaining municipalities in the Community of Madrid.

This classification is used to compare registration patterns between the regional capital and the rest of the region.

## Missing values

Missing values are retained or removed depending on the analytical purpose.

The treatment of missing values will be documented separately for:

- Descriptive analysis.
- Multivariate analysis.
- Cluster analysis.
- Temporal analysis.
- Vehicle-technology comparisons.

## Data-quality considerations

The dataset may contain:

- Inconsistent manufacturer and model names.
- Missing technical specifications.
- Categories recorded using different formats.
- Registration municipalities that differ from the place where the vehicle is actually used.
- Unusually high municipal totals linked to renting companies, corporate fleets or taxation differences.

These limitations must be considered when interpreting territorial results.

## Pending validation

The following information will be validated against the official DGT documentation before the final public release:

- Measurement units.
- Complete code-label correspondence.
- Valid category ranges.
- Definitions of derived variables.
- Final list of variables included in each analytical stage.