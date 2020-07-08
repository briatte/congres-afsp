setwd('/Users/fr/Documents/Code/congres-afsp/geonames-marion')

library(tidyverse)
library(geonames)
options(geonamesUsername = "marionmai")

cities <- readr::read_tsv("cities.tsv")

citiesdf <-
  cities %>%
  split(.$city) %>%
  map( ~ GNsearch(name = .x$city, country = .x$ISO2_dest, featureCode = "PPL", fuzzy = 1)) %>%
  compact() %>%
  map_dfr(~ .x %>% as_tibble(), .id = "city_src")#  %>% # (.)
  # full_join(country, by = c("city_src" = "city")) %>% #"country_src"
  # rename(cityname = toponymName,
  #        provincename = adminName,
  #        countryname = countryName,
  #        long = lng,
  #        lat = lat) %>%
  # select(cityname, provincename, countryname, long, lat)%>%
  # distinct()

readr::write_rds(citiesdf, "geonames-result.rds")
