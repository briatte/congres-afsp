R code to build panel co-attendance networks from [AFSP conferences](http://www.afsp.info/).

# DATA

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

# HOWTO

```{r}
# dependencies, repeated in scripts

# data
library(dplyr)
library(readr)
library(stringr)

# networks
library(ggplot2)
library(ggraph)
library(igraph)

# make

source("01_data.r")
source("02_network.r")
```
