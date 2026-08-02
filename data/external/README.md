# External Data

This directory is reserved for external datasets required by the project but not distributed with the repository.

## Municipal boundaries

The territorial analysis uses a municipal boundary dataset for the Community of Madrid.

The original thesis used the following shapefile:

```text
recintos_municipales_inspire_peninbal_etrs89.shp
```

The geographic data are used to:

- Retain municipal administrative units.
- Restrict the map to the Community of Madrid.
- Match DGT municipality names to geographic features.
- Produce municipal choropleth maps.
- Visualise the analytical territorial classification.

The territorial workflow expects the shapefile and its associated files to be stored inside:

```text
data/external/geospatial/
```

A shapefile normally requires several associated files sharing the same base name, including:

```text
.shp
.shx
.dbf
.prj
```

These source files are excluded from Git and are not covered by the repository's MIT License.

## Expected geographic fields

The original analytical workflow uses the following attributes:

| Field | Purpose |
|---|---|
| `NAMEUNIT` | Official municipality name. |
| `NATLEVNAME` | Administrative level used to retain municipalities. |
| `CODNUT3` | Geographic code used to restrict the data to the Community of Madrid. |

The final territorial script applies:

```r
NATLEVNAME == "Municipio"
CODNUT3 == "ES300"
```

## Reproducibility

Users wishing to reproduce the territorial maps must obtain a compatible municipal boundary dataset separately and place all required files in the geospatial directory.

The public scripts will use relative paths and will never depend on a user-specific local directory.