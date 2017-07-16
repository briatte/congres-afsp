R code to build panel co-attendance networks from [AFSP](http://www.afsp.info/) biennial conferences.

# CITATION

Briatte, François. 2017. _AFSP Conference Panel Co-attendance Data._ DOI: [10.5281/zenodo.823352](https://doi.org/10.5281/zenodo.823352).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.823352.svg)](https://doi.org/10.5281/zenodo.823352)

# DATA

The [DATA](DATA.md) file contains a detailed codebook for all files present in the `data` folder.

# HOWTO

```r
# PACKAGE DEPENDENCIES (repeated in scripts)

# data
library(dplyr)
library(readr)
library(rvest)
library(stringr)

# networks
library(igraph)
library(ggplot2)
library(ggraph)

# BUILD NETWORKS

# full construction routine
source("01_data.r")
source("02_networks.r")

# to load the edge list on its own
d <- readr::read_csv("data/edges.csv", col_types = "icciiiiccc")

# to load the weighted incidence matrix on its own
w <- readRDS("data/incidence_matrix.rds")

# PANEL DATA

# to read the panel information data
p <- readr::read_tsv("data/panels.tsv", col_types = "iccc")

# to check that all panel identifiers match
dplyr::mutate(p, j = stringr::str_c(year, "_", id)) %>% 
  dplyr::inner_join(d, by = c("year", "j")) %>% 
  nrow(.) == nrow(d)
```

# LICENSE

The contents of this repository are released under a [Creative Commons Attribution-NonCommercial-ShareAlike](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
