R code to build panel co-attendance networks from [AFSP](http://www.afsp.info/) biennial conferences.

# CITATION

Briatte, François. 2017. _AFSP Conference Panel Co-attendance Networks._ DOI: [10.5281/zenodo.822976](https://doi.org/10.5281/zenodo.822976).

[![DOI](https://zenodo.org/badge/96291301.svg)](https://zenodo.org/badge/latestdoi/96291301)

# DATA

Contents of the [`edges.csv`](https://github.com/briatte/congres-afsp/blob/master/data/edges.csv) data object:

- `year` – Year of AFSP conference ([2009][2009], [2011][2011], [2013][2013], [2015][2015], [2017][2017]).
- `i` – Full name of the attendee, slightly simplified for cross-year matching:
  - Coded as `FAMILY NAME FIRST NAME`, all uppercase.
  - Composed family names `X-Y` are simplified to their first component `X`.
  - Dashes in names (e.g. `MARIE-CLAUDE`) have been removed.
- `j` – Panel attended, coded as `YEAR_ID`, where `ID` contains:
  - The type of panel (e.g. `CP` for plenary conferences, `ST` for thematic sessions).
  - The alphanumeric identifier of the panel when there was one.
- `n_j` – Number of attendees to the conference panel.
- `n_p` – Number of conference panels attended that year by the attendee.
- `t_p` – Total number of panels attended by the attendee.
- `t_c` – Total number of conferences attended by the attendee.

[2009]: http://www.afsp.info/archives/congres/congres2009/programmes/indexnoms.html
[2011]: http://www.afsp.info/archives/congres/congres2011/programme/index.html
[2013]: http://www.afsp.info/archives/congres/congres2013/indexducongres.html
[2015]: http://www.afsp.info/archives/congres/congres2015/indexcongres.html
[2017]: http://www.afsp.info/congres/congres-2017/index/

The [`incidence_matrix.rds`](https://github.com/briatte/congres-afsp/blob/master/data/incidence_matrix.rds) data object contains the _i_ &times; _j_ incidence matrix, with each tie weighted by 1 / _n<sub>j</sub>_.

The `panels.csv` file has additional information on all conference panels:

- `year` – Year of AFSP conference (2009, 2011, 2013, 2015, 2017).
- `id` – Panel identifier that matches the `ID` part of the `j` variable in `edges.csv`.
- `title` – Panel title, slightly cleaned up:
  - Multiples spaces were replaced by a single one.
  - Double quotes are coded as « French quotes » (_chevrons_).
  - Single quotes are coded as « l’apostrophe ».
  - Unbreakable spaces are used before ":" and "?" (no occurrences of ";" and "!") and before/after double quotes.
  - All instances of "_État_" (the State) are accentuated.
- `notes` – Notes, in French, when available (e.g. to indicate the panel was postponed).

The data were manually extracted from the relevant [AFSP Web pages](http://www.afsp.info/congres/editions-precedentes/). A handful of panels listed in the file have no participants listed in the `edges.csv` file, for various reasons (e.g. panel was cancelled, panel is a PhD workshop with no attendees list).

# HOWTO

```r
# PACKAGE DEPENDENCIES (repeated in scripts)

# data
library(dplyr)
library(readr)
library(stringr)

# networks
library(ggplot2)
library(ggraph)
library(igraph)

# BUILD NETWORKS

# complete run
source("01_data.r")
source("02_networks.r")

# to load the edge list on its own
d <- readr::read_csv("data/edges.csv", col_types = "icciiii")

# to load the weighted incidence matrix on its own
w <- readRDS("data/incidence_matrix.rds")

# PANEL DATA

# to read the panel information data
p <- readr::read_csv("data/panels.csv", col_types = "iccc")

# to check that all panel identifiers match
dplyr::mutate(p, j = stringr::str_c(year, "_", id)) %>% 
  dplyr::inner_join(d, by = c("year", "j")) %>% 
  nrow(.) == nrow(d)
```
