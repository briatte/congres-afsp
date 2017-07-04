R code to build panel co-attendance networks from [AFSP conferences](http://www.afsp.info/).

# DATA

- `year` -- Year of AFSP conference (2009, 2011, 2013, 2015, 2017).
- `i` -- Full name of the attendee, slightly simplified for cross-year matching:
  - Coded as `FAMILY NAME FIRST NAME`, all uppercase.
  - Composed family names `X-Y` are simplified to their first component `X`.
  - Dashes in names (e.g. `MARIE-CLAUDE`) have been removed.
- `j` -- Panel attended, coded as `YEAR_ID`, where `ID` contains:
  - The type of panel (e.g. `CP`for plenary, `ST` for thematic).
  - The alphanumeric identifier of the panel when there was one.
- `n_j` -- Number of attendees to the conference panel.
- `n_p` -- Number of conference panels attended that year by the attendee.
- `t_p` -- Total number of panels attended by the attendee.
- `t_c` -- Total number of conferences attended by the attendee.

# HOWTO

```{r}
# dependencies, repeated in scripts
library(dplyr)
library(igraph)
library(readr)
library(stringr)

# make
source("01_data.r")
source("02_network.r")
```
