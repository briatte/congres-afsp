library(dplyr)
library(readr)
library(stringr)

dir.create("data", showWarnings = FALSE)
dir.create("html", showWarnings = FALSE)

# ==============================================================================
# DATA :: ATTENDEE INDEXES
# ==============================================================================

y <- c("http://www.afsp.info/congres/congres-2017/index/",
  "http://www.afsp.info/archives/congres/congres2015/indexcongres.html",
  "http://www.afsp.info/archives/congres/congres2013/indexducongres.html",
  "http://www.afsp.info/archives/congres/congres2011/programme/index.html",
  "http://www.afsp.info/archives/congres/congres2009/programmes/indexnoms.html")

d <- data_frame()

cat("[PARSING] attendee indexes for", length(y), "conferences:\n\n")
for (i in rev(y)) {
  
  f <- str_c("html/", str_extract(i, "\\d{4}"), ".html")
  if (!file.exists(f)) {
    download.file(i, f, mode = "wb", quiet = TRUE)
  }
  
  cat("", f)
  f <- read_lines(f) %>% 
    # AD   : atelier (2015, 2017)
    # CP   : conférence plénière, pas toujours numérotée (toutes éditions)
    # MD   : module (2009)
    # MDFB : module (2015)
    # MPP  : module (2013)
    # MTED : module (2015)
    # ST : section thématique (toutes éditions)
    # - parfois numérotées DD.D : 12.1, 12.2 (2009)
    # - parfois spéciales : 'ST RC20IPSA', 'ST PopAct' (2015)
    # excluded: single, unnumbered TR (2013)
    str_subset("(AD|CP|MD|MPP|MTED|ST)\\s?(\\d|GRAM|GrePo|PopAct|RC)|\\s(MDFB|CP)") %>%
    # transliterate, using sub to keep strings with non-convertible bytes
    iconv(to = "ASCII//TRANSLIT", sub = " ") %>%
    # remove diacritics
    str_replace_all("[\"^'`\\.]|&#8217;|&(l|r)squo;", "") %>%
    # remove loose HTML tags
    str_replace_all("<br\\s?/?>|<(p|b|li|span)(.*?)>|</(p|b|li|span)>", "") %>%
    # remove French/Spanish name particles
    str_replace_all(regex("\\s\\(d(a|e)\\)", ignore_case = TRUE), "") %>%
    # fix spaces (keep before next)
    str_replace_all("(\\s|&nbsp;)+", " ") %>% 
    # &eacute, &icirc -> e, i
    str_replace_all("&(\\w{1})(.*?);", "\\1") %>% 
    # lone initials within name
    str_replace_all("\\s[A-Za-z]{1}\\s", " ") %>% 
    # lone initials at end of name + extra spaces
    str_replace_all("(\\s[A-Za-z])+,|\\s+,", ",") %>% 
    str_trim %>% 
    data_frame(year = str_extract(f, "\\d{4}"), i = .)
  
  cat(":", nrow(f), "lines\n")
  d <- rbind(d, f)
  
}

# make sure that every row has at least one comma
d$i <- str_replace(d$i, "([a-z]+)\\s(AD|CP|MD|MPP|MTED|ST|TR)", "\\1, \\2") %>% 
  str_to_upper

# rows with ';' are all false positives, as are rows without ','
d <- filter(d, str_detect(i, ","), !str_detect(i, ";|^\\("))

# real counts for comparison (established by hand):
# 2009 = 725 (got all)
# 2013 = 862 (got all)
# 2017 = 756 (missing 2)
cat("\nAttendees per conference:\n")
print(table(d$year))

# how many participations in a single conference?
table(str_count(d$i, ","))

# ==============================================================================
# EDGES
# ==============================================================================

# add year to panel ids and coerce to (year, i, j) data frame
d <- mapply(function(year, i) {
  x <- unlist(str_split(i, ",\\s?"))
  x[ -1 ] <- str_replace_all(x[ -1 ], "\\s+", "") # ST 0 -> ST0
  str_c(x[ 1 ], "::", str_c(year, "_", x[ -1 ])) # NAME : YEAR_ST0, ST1, ...
}, d$year, d$i) %>% 
  unlist %>% 
  as.vector %>% 
  lapply(function(x) {
    data_frame(
      year = str_extract(x, "\\d{4}"), # year
      i = str_extract(x, "(.*)::"),    # attendee
      j = str_extract(x, "::(.*)")     # panel
    )
  }) %>% 
  bind_rows %>% 
  # remove separator from attendee and panel names
  mutate_at(2:3, str_replace, pattern = "::", replacement = "")

# ==============================================================================
# FINALIZE
# ==============================================================================

# finalize attendee names

# (1) remove composed family names to avoid married 'x-y' duplicates
d$i <- str_replace(d$i, "^(\\w+)-(.*)\\s", "\\1 ")

# fix some problematic rows
# - many caused by extra comma between first and last names
# - many caused by name inversions, esp. among foreigners

d$i[ d$year == 2009 & d$i == "HAMEL CHISTOPHER" ] <- "HAMEL CHRISTOPHER"
d$i[ d$year == 2009 & d$i == "TEJERINA BEJAMIN" ] <- "TEJERINA BENJAMIN"
d$i[ d$year == 2009 & d$i == "THOMAS MARIONA" ] <- "TOMAS FORNES MARIONA"
d$i[ d$year == 2009 & d$i == "SAFI KATAYOUN" ] <- "KATAYOUN SAFI"
d$i[ d$year == 2009 & d$i == "SUMBUL KAYA" ] <- "KAYA SUMBUL"
d$i[ d$year %in% c(2009, 2015) & d$i == "VISSCHER CHRISTIAN DE" ] <- "VISSCHER CHRISTIAN"
d$i[ d$year == 2011 & d$i == "LOUAFI DELIM" ] <- "LAOUFI SELIM"
d$i[ d$year == 2013 & d$i == "ABEL FRANCOIS" ] <- "FRANCOIS ABEL"
d$i[ d$year == 2013 & d$i == "ABENA-TSOUNGI" ] <- "ABENA-TSOUNGI ALAIN"
d$i[ d$year == 2013 & d$i == "DEBOCK CAMILLE" ] <- "BEDOCK CAMILLE"
d$i[ d$year == 2013 & d$i == "DE SIO LORENZI" ] <- "DE SIO LORENZO"
d$i[ d$year == 2013 & d$i == "DUSCHINSKY MICHAEL PINTO" ] <- "PINTO DUSCHINSKY MICHAEL"
d$i[ d$year == 2013 & d$i == "PILLON" ] <- "PILLON JEAN-MARIE"
d$i[ d$year == 2015 & d$i == "JIMENEZ FERNADO" ] <- "JIMENEZ FERNANDO"
d$i[ d$year == 2015 & d$i == "LENGUITA" ] <- "LENGUITA PAULA"
d$i[ d$year == 2015 & d$i == "MATUKHNO NATALIA NATALIA" ] <- "MATUKHNO NATALIA"
d$i[ d$year == 2017 & d$i == "BLEUWENN BLEUWENN" ] <- "LECHAUX BLEUWENN"
d$i[ d$year == 2017 & d$i == "BILLOWS BILLOWS" ] <- "BILLOWS SEBASTIEN"
d$i[ d$year == 2017 & d$i == "EVRARD AURELIEN EVRARD" ] <- "EVRARD AURELIEN"
d$i[ d$year == 2017 & d$i == "GONZALES-GONZALESVERONICA" ] <- "GONZALES VERONICA"
d$i[ d$year == 2017 & d$i == "KEFALA VIVI" ] <- "VIVI KEFALA"
d$i[ d$year == 2017 & d$i == "SOULE FOLASAHDE" ] <- "SOULE FOLASHADE"

# convenience fixes
# - mostly simplifications of foreign names
# - Korean names 'Kil-Ho' and 'Sung-Eun' simplified by losing dash,
#   as seems to have been commonly done in the original data
d$i[ d$year == 2009 & d$i == "NGAMCHARA MBOUEMBOUE" ] <- "NGAMCHARA CAROLINE"
d$i[ d$year == 2009 & d$i == "SHIM SUNG-EUN" ] <- "SHIM SUNGEUN"
d$i[ d$year == 2013 & d$i %in% c("AMADO BORTHAYRE LONTZI", "LONTZI AMADO-BORTHAYRE") ] <- "AMADO LONTZI"
d$i[ d$year == 2015 & d$i == "MONTEIRO BENTO RODRIGO PEREIRA" ] <- "MONTEIRO BENTO"
d$i[ d$year == 2015 & d$i == "NOSTITZ FELIX-CHRISTOPHER VON" ] <- "NOSTITZ FELIX"
d$i[ d$year == 2015 & d$i == "TAWA LAMA-REWAL" ] <- "TAWA STEPHANIE"
d$i[ d$year == 2015 & d$i == "YONG KWON HYEOK" ] <- "HYEOK KWON"
d$i[ d$year == 2017 & d$i == "HOUTE ARNAUD DOMINIQUE" ] <- "HOUTE ARNAUD"
d$i[ d$year == 2017 & d$i == "LEE KIL-HO" ] <- "LEE KILHO"
d$i[ d$year == 2017 & d$i == "NDONGMO BERTRAND MAGLOIRE" ] <- "NDONGMO BERTRAND"

# # to detect (several forms of, but not all) errors:
# str_split(d$i, " ") %>% sapply(function(x) x[1] == x[2]) %>% which
# str_split(d$i, " ") %>% sapply(function(x) x[1] == x[3]) %>% which
# str_split(d$i, " ") %>% sapply(function(x) x[2] == x[3]) %>% which

# no remaining problematic rows
stopifnot(str_detect(d$i, "\\s"))

# (2) remove dashes to avoid 'marie claude' and 'marie-claude' duplicates
d$i <- str_replace_all(d$i, "-", " ")

# finalize panel names

# fix sessions with no type (all are 2009, all are ST)
d$j <- str_replace(d$j, "_(\\d+)$", "_ST\\1")

# fix sessions with an extra comma between type and id (one case in 2009)
d$j <- str_replace(d$j, "ST, (\\d+)$", "_ST\\1")

# remove panels with less than 2 attendees (false positives)
d <- group_by(d, year, j) %>% 
  summarise(n_j = n()) %>% 
  filter(n_j > 1) %>% 
  inner_join(d, ., by = c("year", "j")) %>% 
  distinct(.keep_all = TRUE)

# safety measure to avoid duplicate rows

# ==============================================================================
# COUNTS
# ==============================================================================

# how many participations over the 5 conferences?
t <- group_by(d, i) %>% 
  summarise(t_c = n_distinct(year)) %>% 
  arrange(-t_c)

table(t$t_c) # 35 attendees went to all conferences, ~ 1,800+ went to only 1
table(t$t_c > 1) / nrow(t) # over 70% attended only 1 of 5 conferences in 8 years

# number of panels overall
n_distinct(d$j)

# number of panels in each conference
cat("\nPanels per conference:\n\n")
print(tapply(d$j, d$year, n_distinct))

# add number of panels attended per conference
# (useful for edge weighting)
d <- summarise(group_by(d, year, i), n_p = n()) %>% 
  inner_join(d, ., by = c("year", "i"))

# add total number of panels attended and total number of conferences attended
# (useful for vertex subsetting)
d <- summarise(group_by(d, i), t_p = n_distinct(j), t_c = n_distinct(year)) %>% 
  inner_join(d, ., by = "i")

# ==============================================================================
# FIND FIRST NAMES
# ==============================================================================

f <- "data/prenoms2016.zip"

if (!file.exists(f)) {
  
  cat(
    "\n[DOWNLOADING] Fichier des prénoms, Édition 2016",
    "\n[SOURCE] https://www.insee.fr/fr/statistiques/2540004",
    "\n[DESTINATION]", f,
    "\n"
  )
  
  p <- "https://www.insee.fr/fr/statistiques/fichier/2540004/nat2015_txt.zip"
  download.file(p, f, mode = "wb", quiet = TRUE)
  
}

p <- read_tsv(f, locale = locale(encoding = "latin1"), col_types = "iccd") %>% 
  filter(preusuel != "_PRENOMS_RARES", str_count(preusuel) > 2) %>% 
  mutate(preusuel = iconv(preusuel, to = "ASCII//TRANSLIT", sub = " ") %>%
           # remove diacritics
           str_replace_all("[\"^'`\\.]|&#8217;|&(l|r)squo;", "") %>% 
           # make 'marie claude' and 'marie-claude' the same
           str_replace_all("-", " ")) %>%
  group_by(preusuel) %>% 
  summarise(p_f = sum(nombre[ sexe == 2 ]) / sum(nombre)) %>% 
  rename(first_name = preusuel)

a <- select(d, year, i, j) %>% 
  distinct

# extract first names
a$first_name <- if_else(
  str_detect(a$i, " (ANNE|JEAN|MARIE) \\w+$"), # e.g. Jean-Marie, Marie-Claude
  str_replace(a$i, "(.*)\\s(.*)\\s(\\w+)", "\\2 \\3"),
  str_replace(a$i, "(.*)\\s(.*)", "\\2")
)

stopifnot(!is.na(a$first_name)) # sanity check

# ==============================================================================
# FIND GENDERS
# ==============================================================================

a$found_name <- a$first_name %in% unique(p$first_name)
a <- left_join(a, p, by = "first_name") %>% 
  mutate(
    p_f = if_else(p_f > 0.85, 1, p_f),
    p_f = if_else(p_f < 0.1, 0, p_f) # 'Claude' is .12, so keep this one lower
  )

# manually collected values
f <- read_tsv("data/genders.tsv", col_types = "cc") %>% 
  filter(gender %in% c("f", "m")) # remove missing values

a$p_f[ a$i %in% f$name[ f$gender == "f" ] ] <- 1 # females
a$p_f[ a$i %in% f$name[ f$gender == "m" ] ] <- 0 # males

# ==============================================================================
# FINALIZE FIRST NAMES
# ==============================================================================

# identify names as found
a$found_name[ !a$found_name & a$p_f %in% 0:1 ] <- TRUE

# missing less than 100 missing values
a$first_name <- if_else(a$found_name, a$first_name, NA_character_)

a$family_name <- if_else(
  is.na(a$first_name),
  str_replace(a$i, "(.*)\\s(.*)", "\\1"),
  str_replace(a$i, a$first_name, "") %>% 
    str_trim
)

# sanity check
stopifnot(!is.na(a$family_name))

cat(
  "\n[MISSING] First names of",
  n_distinct(a$i[ is.na(a$first_name) ]),
  "attendees\n"
)

# ==============================================================================
# FINALIZE GENDERS
# ==============================================================================

# missing less than 100 missing values
a$gender <- recode(a$p_f, `1` = "f", `0` = "m", .default = NA_character_)

# # for manual checks:
# filter(a, !p_f %in% c(0, 1)) %>% View

# save manually collected values, with missing values back again
data_frame(gender = NA_character_, name = a$i[ is.na(a$first_name) ]) %>% 
  bind_rows(f) %>% 
  arrange(name) %>% 
  write_tsv("data/genders.tsv")

cat(
  "[MISSING] Gender of",
  n_distinct(a$i[ is.na(a$gender) ]),
  "attendees\n"
)

# ==============================================================================
# EXPORT TO CSV
# ==============================================================================

write_csv(
  select(a, -found_name, -p_f) %>% 
    left_join(d, ., by = c("year", "i", "j")),
  "data/edges.csv"
)

cat(
  "\n[SAVED]",
  nrow(d),
  "rows,", 
  n_distinct(d$i),
  "attendees,",
  n_distinct(d$j),
  "panels."
)

# kthxbye
