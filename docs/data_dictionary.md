# Data Dictionary

This document describes the variables contained in the cleaned master dataset and the main derived variables created during the analytical workflow.

The definitions are based on the final data-preparation and analysis scripts used in the Bachelor's Thesis.

## 1. Master dataset

The cleaned master dataset contains **3,115,063 valid new passenger car registrations** from the Community of Madrid between January 2015 and December 2025.

The final dataset stored during the original project contained 22 variables.

| Variable | R data type | Description | Analytical use |
|---|---|---|---|
| `FEC_MATRICULA` | Date | Date on which the passenger car was registered. | Temporal aggregation and definition of the study period. |
| `MARCA_ITV` | Character | Vehicle manufacturer or brand recorded in the ITV technical data. | Brand rankings and descriptive analysis. |
| `MODELO_ITV` | Character | Vehicle model recorded in the ITV technical data. | Model rankings and descriptive analysis. |
| `COD_TIPO` | Character | DGT code identifying the vehicle type. | Used to restrict the sample to the relevant passenger-car types. |
| `COD_PROPULSION_ITV` | Character | DGT code identifying the propulsion system. | Used with the electric-vehicle category to derive the final propulsion groups. |
| `IND_NUEVO_USADO` | Character | Indicator distinguishing new and used vehicles. | The final sample retains records coded as new vehicles. |
| `PERSONA_FISICA_JURIDICA` | Character | Indicator identifying whether the registered owner is an individual or a legal entity. | Ownership analysis, territorial analysis and FAMD. |
| `SERVICIO` | Character | Administrative service or use code associated with the vehicle. | Codes outside the analytical scope are excluded during cleaning. |
| `CILINDRADA_ITV` | Integer | Engine displacement recorded in the ITV technical data. | Technical analysis and FAMD; measured in cubic centimetres. |
| `POTENCIA_ITV` | Double | Power-related field contained in the ITV technical data. | Retained in the master dataset, although `KW_ITV` is used as the main power variable in the final analyses. |
| `TARA` | Integer | Unladen vehicle weight. | Descriptive characterisation of vehicle size and weight. |
| `MUNICIPIO` | Character | Municipality in which the vehicle is administratively registered. | Municipal and territorial analysis. |
| `CO2_ITV` | Integer | Reported CO2 emissions in the ITV technical data. | Environmental analysis and construction of normalised emissions. |
| `RENTING` | Character | Indicator showing whether the vehicle is associated with renting. | Territorial analysis, market profiling and FAMD. |
| `CARROCERIA` | Character | Vehicle body-type code or description. | Descriptive characterisation of passenger cars. |
| `NIVEL_EMISIONES_EURO_ITV` | Character | European emissions-standard category. | Environmental and technological analysis. |
| `CONSUMO_WH_KM_ITV` | Integer | Reported electrical energy consumption in watt-hours per kilometre. | Electric-vehicle analysis and FAMD. |
| `CATEGORIA_VEHICULO_ELECTRICO` | Character | Electric-vehicle category recorded by the DGT. | Identification of hybrid, plug-in hybrid and range-extended technologies. |
| `AUTONOMIA_VEHICULO_ELECTRICO` | Integer | Reported electric driving range. | Descriptive analysis of electrified vehicles. |
| `DISTANCIA_EJES_12_ITV` | Integer | Distance between the first and second axles. | Structural vehicle-size indicator and FAMD. |
| `periodo` | Character | Six-digit source period extracted from the monthly filename in `YYYYMM` format. | Identification of the source month and temporal validation. |
| `KW_ITV` | Double | Maximum net power recorded in kilowatts. | Main vehicle-power variable in the descriptive analysis and FAMD. |

## 2. Import-only and filtering variables

The original DGT interface contains 69 fixed-width fields.

Several fields are required during import and cleaning but are not retained in the final master dataset.

| Variable | Purpose |
|---|---|
| `COD_CLASE_MAT` | Used to retain the vehicle classes included in the final passenger-car sample. |
| `COD_PROVINCIA_VEH` | Used to restrict the analysis to registrations associated with the Community of Madrid. |
| `IND_BAJA_DEF` | Used to exclude vehicles with a definitive administrative withdrawal. |
| `IND_BAJA_TEMP` | Used to exclude vehicles with a temporary administrative withdrawal. |
| `BAJA_TELEMATICA` | Used to exclude vehicles with a telematic withdrawal record. |
| `FEC_TRAMITACION` | Imported and converted to date format during initial processing. |
| `FEC_TRAMITE` | Imported and converted to date format during initial processing. |
| `FEC_PRIM_MATRICULACION` | Imported and converted to date format during initial processing. |
| `FEC_PROCESO` | Imported and converted to date format during initial processing. |
| `COD_MUNICIPIO_INE_VEH` | Imported as a municipal identifier but not retained in the final master dataset. |
| `CODIGO_POSTAL` | Imported and converted during the initial reading stage. |
| `IND_SUSTRACCION` | Administrative field available in the source interface. |

The complete list of 69 original fields and their fixed widths will be documented in the public import script.

## 3. Final selection criteria

The original data-preparation script applies the following filters:

```r
COD_CLASE_MAT %in% c("0", "1", "3", "8")
COD_TIPO %in% c("24", "25", "40")
COD_PROVINCIA_VEH == "M"
IND_NUEVO_USADO == "N"
```

The following service codes are excluded:

```r
SERVICIO %in% sprintf("A%02d", 1:20)
```

Records are also excluded when any of the following withdrawal fields contains a value:

```r
IND_BAJA_DEF
IND_BAJA_TEMP
BAJA_TELEMATICA
```

These conditions define the master dataset used in the final thesis.

## 4. Missing-value representation

The fixed-width source files contain several representations of unavailable information.

During import, the following values are converted to `NA`:

- Empty character strings.
- Fields containing only whitespace.
- Strings composed exclusively of asterisks.
- Specific placeholder strings such as `*****`, `******` and `*******`.

All source variables are initially read as character data before applying the required date and numerical conversions.

## 5. Main recoded variables

### 5.1 Propulsion technology

The analytical variable `tipo_propulsion` is derived from `COD_PROPULSION_ITV` and `CATEGORIA_VEHICULO_ELECTRICO`.

| Derived category | Original condition |
|---|---|
| `Hibrido` | `CATEGORIA_VEHICULO_ELECTRICO` is `PHEV`, `HEV` or `REEV`. |
| `Electrico` | `COD_PROPULSION_ITV` is `2`. |
| `Gasolina` | `COD_PROPULSION_ITV` is `0`. |
| `Diesel` | `COD_PROPULSION_ITV` is `1`. |

The electric-vehicle category is evaluated before the general propulsion code so that hybrid technologies are classified correctly.

### 5.2 Renting

The original `RENTING` variable is recoded as:

| Original value | Analytical category |
|---|---|
| `S` | `Si` |
| `N` | `No` |
| Other or unavailable | Missing |

### 5.3 Ownership type

The original `PERSONA_FISICA_JURIDICA` variable is recoded as:

| Original value | Analytical category |
|---|---|
| `D` | `Fisica` |
| `X` | `Juridica` |
| Other or unavailable | Missing |

## 6. Derived temporal variables

| Variable | Type | Definition |
|---|---|---|
| `periodo` | Character | Source month extracted from the original filename in `YYYYMM` format. |
| `periodo_fecha` | Date | First day of the corresponding registration month. |
| `anio` | Integer | Calendar year extracted from `FEC_MATRICULA`. |
| `mes` | Integer or ordered factor | Calendar month used for monthly aggregation and seasonality analysis. |
| `grupo_norma` | Character | Emissions-measurement period: `NEDC` before 2021 and `WLTP` from 2021 onwards. |

In several analysis documents, the monthly period is reconstructed directly from `FEC_MATRICULA` using the first day of each month.

## 7. Derived territorial variables

Municipality names are standardised before joining the registration data to geographic information.

| Variable | Type | Description |
|---|---|---|
| `municipio_std` | Character | Normalised municipality name used for matching and aggregation. |
| `municipio_nombre` | Character | Display name obtained after matching the source municipality to the municipal map. |
| `grupo_territorial` | Factor | Territorial classification used to distinguish Madrid city, metropolitan or business municipalities, atypical peripheral municipalities and the remaining municipalities. |
| `renting_norm` | Character | Standardised `S` or `N` version of the renting indicator. |
| `titularidad_norm` | Character | Standardised ownership category: individual or legal entity. |
| `ano_matricula` | Integer | Registration year used in the territorial time analysis. |

Municipality standardisation includes:

- Conversion to uppercase.
- Removal of accents.
- Removal of punctuation.
- Normalisation of whitespace.
- Manual correction of unmatched municipality names where required.

## 8. Variables used in the FAMD

The final Factor Analysis of Mixed Data uses eight variables.

### Quantitative variables

| Variable | Treatment before FAMD |
|---|---|
| `CILINDRADA_ITV` | Set to zero for electric vehicles; non-positive values are treated as missing for other propulsion types. |
| `KW_ITV` | Values below 10 kW are excluded from the FAMD analytical sample. |
| `CO2_norm` | Standardised CO2 value calculated separately within the NEDC and WLTP periods. |
| `CONSUMO_WH_KM_ITV` | Set to zero for petrol and diesel vehicles; negative values are treated as missing. |
| `DISTANCIA_EJES_12_ITV` | Restricted to values between 1,000 and 6,000 in the FAMD analytical sample. |

### Qualitative variables

| Variable | Categories |
|---|---|
| `tipo_propulsion` | `Gasolina`, `Diesel`, `Hibrido`, `Electrico` |
| `RENTING` | `Si`, `No` |
| `PERSONA_FISICA_JURIDICA` | `Fisica`, `Juridica` |

## 9. Normalised CO2 emissions

The variable `CO2_norm` is created to reduce the comparability problem caused by the transition from NEDC to WLTP measurement standards.

The workflow defines:

```r
grupo_norma = if_else(anio < 2021, "NEDC", "WLTP")
```

CO2 emissions are then standardised separately within each group:

```r
CO2_norm = as.numeric(scale(CO2_ITV))
```

This variable represents a vehicle's relative emissions position within its applicable measurement period. It should not be interpreted as an absolute emissions value in grams per kilometre.

Electric vehicles are assigned a CO2 value of zero before standardisation.

## 10. FAMD and clustering outputs

The factorial and clustering stages generate additional analytical variables.

| Variable | Description |
|---|---|
| `id` | Sequential identifier used to preserve row alignment between the cleaned data and factorial coordinates. |
| `Dim.1`–`Dim.8` | Original individual coordinates produced by the eight-component FAMD solution. |
| `Dim1`–`DimN` | Renamed subset of factorial coordinates used for clustering. The workflow selects between three and six dimensions, depending on cumulative explained inertia. |
| `cluster` | Final K-means cluster assignment. |
| `cluster_label` | Descriptive interpretation assigned to each final cluster. |

The final solution contains five clusters representing:

1. Business-oriented hybrid vehicles.
2. Conventional company and renting vehicles.
3. Higher-power and higher-displacement vehicles.
4. Conventional privately owned vehicles.
5. Electric vehicles.

## 11. Data-quality considerations

The following issues must be considered when using the data:

- Technical variables may be missing or not applicable to every propulsion technology.
- The municipality represents the administrative registration location rather than necessarily the place of actual use.
- Corporate fleets and renting companies can strongly affect municipal totals.
- Coding conventions and measurement standards may change over time.
- Brand and model names may contain spelling, formatting or coding inconsistencies.
- Some extreme values may represent valid unusual vehicles rather than data errors.
- The master dataset and each analytical subset contain different numbers of valid observations because their missing-value requirements differ.

## 12. Source-of-truth principle

The public import and cleaning scripts are the authoritative source for:

- Exact variable types.
- Valid source codes.
- Filtering rules.
- Missing-value transformations.
- Derived-variable definitions.

This dictionary will be updated whenever the final public scripts introduce a documented change.