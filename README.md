# Script for data preparation

This repository contains scripts for preparing environmental data to complement in-situ data from sampling sites for the study:  

Čížek, O., Marhoul, P., Kadlec, T. et al. Full-elevational gradient dataset on moth diversity and abundance in a temperate mountain range. Sci Data (2026). [https://doi.org/10.1038/s41597-026-06837-9](https://doi.org/10.1038/s41597-026-06837-9)

The materials accompanying the paper were reorganised and edited by AH prior to submission and are available on Figshare [https://doi.org/10.6084/m9.figshare.30290536](https://doi.org/10.6084/m9.figshare.30290536) (data and metadata) and at [https://github.com/antoninhlavacek/Moth_Krkonose](https://github.com/antoninhlavacek/Moth_Krkonose) (scripts).

This repository documents the original analysis workflow and input data prior to that reorganisation.

# Repository description
## input data

- `data/raw/sites.gpkg` - raw site data with in-situ measurements
- `scripts/0_download_env.r` - downloading environmental data. In the case of CLES there are registration instruction and download links

## processing
- data processing (can be run in parallel)
    - `scripts/1_dmr5g.r` - processing of DMR5G data
    - `scripts/1_es.r` - processing of CLES data
- `scripts/2_merge_env.r` - merging environmental data

## output data
- `outputs/sites_env.csv` - resulting dataset containing site data with environmental variables

## metadata
- `metadata/meta.csv` - general description of variables in `sites_env.csv`
- `metadata/es_meta.csv` - description and additional information on CLES dataset


## R session info
- `scripts/session_info.txt` - list of R packages and their versions used for data processing, including the R version
