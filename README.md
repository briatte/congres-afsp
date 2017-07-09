R code to build panel co-attendance networks from [AFSP](http://www.afsp.info/) biennial conferences.

# CITATION

Briatte, François. 2017. _AFSP Conference Panel Co-attendance Data._ DOI: [10.5281/zenodo.823352](https://doi.org/10.5281/zenodo.823352).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.823352.svg)](https://doi.org/10.5281/zenodo.823352)

# DATA

## [`edges.csv`][data-edges]

A CSV file with one row per attendee and per conference panel attended:

- `year` – Year of AFSP conference ([2009][2009], [2011][2011], [2013][2013], [2015][2015], [2017][2017]).
- `i` – Full name of the attendee, slightly simplified for cross-year matching:
  - Coded as `FAMILY NAME FIRST NAME`, all uppercase.
  - Composed family names `X-Y` are simplified to their first component `X`.
  - Dashes in names (e.g. `MARIE-CLAUDE`) have been removed.
  - Lone initials (e.g. `SMITH JOHN K`) have been removed.
  - Name particles (e.g. `X DE Y`) have been removed.
- `j` – Panel attended, coded as `YEAR_ID`, where `ID` contains:
  - The type of panel (e.g. `CP` for plenary conferences, `ST` for thematic sessions).
  - The alphanumeric identifier of the panel when there was one.
- `n_j` – Number of attendees to the conference panel.
- `n_p` – Number of conference panels attended that year by the attendee.
- `t_p` – Total number of panels attended by the attendee.
- `t_c` – Total number of conferences attended by the attendee.
- `first_name` – First name of the attendee.
  - Extracted from `i`, with possible mistakes (see note below).
  - Missing when the first name could not be safely confirmed.
- `family_name` – Family name of the attendee.
  - Extracted from `i`, with possible mistakes (see note below).
- `gender` – Gender of the attendee:
  - Determined from `first_name`, with possible mistakes (see note below).
  - Missing when the gender could not be safely confirmed.

__Note__ – The first name and gender variables are based on the frequencies observed in the [_Fichier Prénoms Insee_, 2016 edition][data-prenoms], which will be downloaded to the `data` folder during data preparation, as well as on manual additions provided in [`genders.tsv`][data-genders] (see below).

[data-edges]: https://github.com/briatte/congres-afsp/blob/master/data/edges.csv
[data-prenoms]: https://www.insee.fr/fr/statistiques/2540004
[2009]: http://www.afsp.info/archives/congres/congres2009/programmes/indexnoms.html
[2011]: http://www.afsp.info/archives/congres/congres2011/programme/index.html
[2013]: http://www.afsp.info/archives/congres/congres2013/indexducongres.html
[2015]: http://www.afsp.info/archives/congres/congres2015/indexcongres.html
[2017]: http://www.afsp.info/congres/congres-2017/index/

## [`genders.tsv`][data-genders]

A TSV (tab-separated) file with one row per attendee present in [`edges.csv`][data-edges] for which gender could not be determined from the [_Fichier Prénoms Insee_, 2016 edition][data-prenoms] (see note above):

- `gender` – Gender of the attendee:
  - Coded as `f` for female, `m` for male, or `NA` if missing.
  - Some, but not yet all, missing values have been manually inputed.
- `name` – Full name of the attendee, coded exactly as `i` in [`edges.csv`][data-edges].

This file can be manually revised to improve the completeness of the `gender` variable in [`edges.csv`][data-edges]. The file will be loaded, possibly updated with new attendee names for which gender could not be determined, and then re-saved during data preparation.

[data-genders]: https://github.com/briatte/congres-afsp/blob/master/data/genders.tsv

## [`incidence_matrix.rds`][data-incidence_matrix]

A serialized R object of class `matrix` representing the _i_ &times; _j_ incidence matrix contained in [`edges.csv`][data-edges], with each edge weighted by 1 / _n<sub>j</sub>_. Because all conference panels have at least two attendees, the edge weights have a maximum value of 0.5.

[data-incidence_matrix]: https://github.com/briatte/congres-afsp/blob/master/data/incidence_matrix.rds

## [`panels.csv`][data-panels]

A CSV file with one row per conference panel:

- `year` – Year of AFSP conference (2009, 2011, 2013, 2015, 2017).
- `id` – Panel identifier that matches the `ID` part of the `j` variable in [`edges.csv`][data-edges].
- `title` – Panel title, slightly cleaned up:
  - Multiples spaces were replaced by a single one.
  - Double quotes are coded as `«` French quotes `»`.
  - Single quotes are coded as `’`.
  - Unbreakable spaces are used before `:;?!` and before/after double quotes.
  - Full stops at the end of titles were removed.
  - All instances of `État` (the State) are accentuated.
- `notes` – Notes, in French, when available (e.g. to indicate the panel was postponed).

The data were manually extracted from the relevant [AFSP Web pages](http://www.afsp.info/congres/editions-precedentes/). A handful of panels listed in the file have no participants listed in [`edges.csv`][data-edges], for various reasons (e.g. the panel was cancelled or postponed, the panel is a PhD workshop with no attendees list).

This file contains slightly better formatted panel titles than those collected during data preparation, and should therefore be preferred when requesting that information. The information contained in the `notes` column are exclusive to that file.

[data-panels]: https://github.com/briatte/congres-afsp/blob/master/data/panels.csv

# HOWTO

```r
# PACKAGE DEPENDENCIES (repeated in scripts)

# data
library(dplyr)
library(readr)
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
p <- readr::read_csv("data/panels.csv", col_types = "iccc")

# to check that all panel identifiers match
dplyr::mutate(p, j = stringr::str_c(year, "_", id)) %>% 
  dplyr::inner_join(d, by = c("year", "j")) %>% 
  nrow(.) == nrow(d)
```
