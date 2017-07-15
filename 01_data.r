library(dplyr)
library(readr)
library(rvest)
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

p <- locale(encoding = "latin1")
p <- read_tsv(f, locale = p, col_types = "iccd", progress = FALSE) %>% 
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
f <- "data/genders.tsv"
p <- read_tsv(f, col_types = "cc") %>% 
  filter(gender %in% c("f", "m")) # remove missing values

a$p_f[ a$i %in% p$name[ p$gender == "f" ] ] <- 1 # females
a$p_f[ a$i %in% p$name[ p$gender == "m" ] ] <- 0 # males

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
  "attendee(s)\n"
)

# ==============================================================================
# FINALIZE GENDERS
# ==============================================================================

# missing less than 100 missing values
a$gender <- recode(a$p_f, `1` = "f", `0` = "m", .default = NA_character_)

# # for manual checks:
# filter(a, !p_f %in% c(0, 1)) %>% View

# save manually collected values, with missing values back again
w <- a$i[ is.na(a$gender) ]
if (length(w) > 0) {
  data_frame(gender = NA_character_, name = w) %>% 
    bind_rows(p) %>% 
    arrange(name) %>% 
    write_tsv(f)
}

cat("[MISSING] Gender of", n_distinct(w), "attendee(s)\n")

# sanity check: all rows in genders.tsv exist in attendees data
stopifnot(read_tsv(f, col_types = "cc")$name %in% unique(a$i))

# ==============================================================================
# EXPORT ATTENDEES TO CSV
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

# ==============================================================================
# DATA :: PANELS
# ==============================================================================

y <- c("http://www.afsp.info/congres/congres-2017/sessions/sections-thematiques/",
       "http://www.afsp.info/archives/congres/congres2015/st.html",
       "http://www.afsp.info/archives/congres/congres2013/st.html",
       "http://www.afsp.info/archives/congres/congres2011/sectionsthematiques/presentation.html",
       "http://www.afsp.info/archives/congres/congres2009/sectionsthematiques/presentation.html")

# initialize panels data
d <- data_frame()

cat("\n\n[PARSING] 'ST' panel indexes for", length(y), "conferences:\n\n")
for (i in rev(y)) {
  
  f <- str_c("html/", str_extract(i, "\\d{4}"), "_panels.html")
  if (!file.exists(f)) {
    download.file(i, f, mode = "wb", quiet = TRUE)
  }
  
  cat("", f)
  f <- read_html(f) %>% 
    html_nodes(xpath = "//a[contains(@href, 'st')]")
  
  j <- str_c("ancestor::", if_else(str_detect(i, "2017"), "p", "li"))
  
  # special cases below are all for 2015
  w <- str_which(html_attr(f, "href"), "st(-|\\d|gram|grepo|popact|rc20ipsa)+(.html|/$)")
  
  w <- data_frame(
    year = as.integer(str_extract(i, "\\d{4}")),
    url = html_attr(f[ w ], "href"),
    id = basename(url) %>%
      str_replace_all(".html|-", "") %>%
      str_to_upper, # matches ids in edges.csv and panels.tsv
    title = html_nodes(f[ w ], xpath = j) %>% 
      html_text(trim = TRUE) %>% 
      str_replace("^ST[\\.\\s\\d/-]+", "") # redundant with (cleaner) panels.tsv
  )
  
  # fix relative URLs
  w$url <- if_else(str_detect(w$url, "^http"), w$url, str_c(dirname(i), "/", w$url))
  
  # avoid 'empty id' mistakes that would overwrite indexes!
  stopifnot(!str_detect(w$id, "st$"))
  
  cat(":", nrow(w), "ST panels\n")
  d <- rbind(d, w)
  
}

# fix mismatch in panel URL / id for one case in 2017
d$id[ str_detect(d$url, "st2-2") ] <- "ST2"

# save only if the cleaner file does not exist
f <- "data/panels.tsv"
if (!file.exists(f)) {
  write_tsv(d, f)
}

# ==============================================================================
# DOWNLOAD PANEL PAGES
# ==============================================================================

# approx. 300 files (quick enough)
cat("\n[DOWNLOADING]", nrow(d), "panel pages\n")

for (i in 1:nrow(d)) {
  
  f <- str_c("html/", d$year[ i ], "_", d$id[ i ], ".html")
  
  if (!file.exists(f)) {
    download.file(d$url[ i ], f, mode = "wb", quiet = TRUE)
  }
  
}

# note: one ST panel of 2015 is missing because it was cancelled/postponed

# ==============================================================================
# PREPARE ATTENDEES AND PANELS DATA
# ==============================================================================

# reduce attendees to unique groups of conference years, attendees and panels
a <- filter(a, str_detect(j, "ST")) %>% 
  select(year, i, j, first_name, family_name) %>% 
  distinct %>% 
  mutate(
    affiliation = if_else(
      is.na(first_name),
      family_name,
      str_c(first_name, "[\\s\\w]+?", family_name, "|", family_name, "[\\s\\w]+?", first_name)
    )
  )

# create panel uid
d$j <- str_c(d$year, "_", d$id)

# ==============================================================================
# EXTRACT NAMES AND AFFILIATIONS
# ==============================================================================

cat("\n[PARSING]", n_distinct(d$j), "panels\n")

for (i in unique(d$j)) {
  
  f <- str_c("html/", i, ".html")
  
  # this is where it gets messy...
  # what we have are on one end are 'standardized' attendee names in uppercase
  # (see README for details), and various strands of not-so-structured HTML on 
  # the other one...
  
  # let's try to match both
  t <- read_html(f) %>% 
    html_nodes(xpath = "//*[contains(text(), '(')]") %>% 
    html_text %>% 
    str_to_upper %>% 
    iconv(to = "ASCII//TRANSLIT", sub = " ") %>%
    # remove diacritics
    str_replace_all("[\"^'`\\.]", "") %>%
    # composed names + handle multiple spaces
    str_replace_all( "-|\\s+", " ") %>% 
    str_trim
  
  # keep only strings likely to match a name and affiliation
  t <- t[ str_detect(t, "\\s") & str_count(t) > 2 & str_count(t) < 5000 ] %>% 
    str_extract("(.*)\\)") # exclude everything after last affiliation
  
  a$affiliation[ a$j == i ] <- sapply(a$affiliation[ a$j == i ], function(x) {
    t[ str_which(t, x)[1] ] %>%
      str_extract(str_c("(", x, ")(.*?)\\)"))
  }) # still returns lists in some cases, don't know why
  
}

# coerce to vector
stopifnot(sapply(a$affiliation, length) == 1)
a$affiliation <- unlist(a$affiliation)

# ==============================================================================
# FINALIZE EXTRACTED AFFILIATIONS
# ==============================================================================

# # fix double sets of opening brackets
# filter(a, str_detect(affiliation, "\\([\\w\\s]+\\(")) %>% View
w <- !is.na(a$affiliation) & str_detect(a$affiliation, "\\([\\w,\\s]+\\(")
a$affiliation[ w ] <- str_replace(a$affiliation[ w ], "(\\([\\w,\\s]+)\\(", "\\1")

# extract affiliations on 'clean' rows
w <- !is.na(a$affiliation) & str_count(a$affiliation, "\\(") == 1
a$affiliation[ w ] <- str_replace(a$affiliation[ w ], "\\((.*)\\)", "\\1")

# remove full names
w <- !is.na(a$first_name)
a$affiliation[ w ] <- str_replace(
  a$affiliation[ w ],
  str_c(a$first_name[ w ], " ", a$family_name[ w ]),
  ""
)

a$affiliation <- str_replace_all(a$affiliation, "\\s+", " ") %>% 
  str_trim

# # some attendees have had a lot of different affiliations...
# group_by(a, i) %>%
#   summarise(n_a = n_distinct(affiliation)) %>%
#   arrange(-n_a)

# ==============================================================================
# EXPORT AND REVISE AFFILIATIONS
# ==============================================================================

a <- select(a, i, j, affiliation) %>% 
  arrange(i, j)

# sanity check: all rows are distinct
stopifnot(nrow(distinct(a)) == nrow(a))

# initialize file if missing
f <- "data/affiliations.tsv"
if (!file.exists(f)) {
  write_tsv(a, f)
}

# specify '.' when merging to ensure that affiliation.x is from panels.tsv
p <- read_tsv(f, col_types = "ccc") %>% 
  full_join(., a, by = c("i", "j"))

# replace empty affiliations with existing ones in panels.tsv
w <- which(is.na(p$affiliation.x) & !is.na(p$affiliation.y))
p$affiliation.x[ w ] <- p$affiliation.y[ w ]
cat("[REPLACED]", length(w), "missing affiliation(s)\n")

# replace 'raw' affiliations with revised ones in panels.tsv
w <- which(p$affiliation.x != p$affiliation.y)
p$affiliation.x[ w ] <- p$affiliation.y[ w ]
cat("[REPLACED]", length(w), "revised affiliation(s)\n")

f <- "data/edges.csv"
p <- select(p, i, j, affiliation = affiliation.x, -affiliation.y) %>% 
  left_join(read_csv(f, col_types = "icciiiiccc"), ., by = c("i", "j"))

cat("\nDistinct attendees:\n\n")
tapply(p$i, p$year, n_distinct) %>%
  print

cat("\nNon-missing attendees:\n\n")
tapply(p$i, p$year, function(x) sum(!is.na(x), na.rm = TRUE)) %>%
  print

cat("\nDistinct affiliations:\n\n")
tapply(p$affiliation, p$year, n_distinct) %>%
  print

cat("\nNon-missing affiliations:\n\n")
tapply(p$affiliation, p$year, function(x) sum(!is.na(x), na.rm = TRUE)) %>%
  print

cat("\nPercentages of non-missing affiliations:\n\n")
f <- function(x) { 100 * sum(!is.na(x), na.rm = TRUE) }
round(tapply(p$affiliation, p$year, f) / table(p$year)) %>%
  print

cat(
  "\n[SAVED]",
  nrow(p),
  "rows,", 
  n_distinct(p$i),
  "attendees,",
  n_distinct(p$j),
  "panels,",
  n_distinct(p$affiliation),
  "affiliations.\n"
)

write_csv(p, "data/edges.csv")

# kthxbye
