# ==============================================================================
# 01 - Download and parse all AFSP Web pages
#
# - See DATA and README files for a guide to the resulting data files.
# - Substantive comments included in the code are marked with [NOTE].
# - Lines required by a specific year of data are marked with it, e.g. [2017].
# - Other comments are sometimes prefixed with [TODO] or [TOFIX].
# ==============================================================================

library(tidyverse) # dplyr, purrr, readr, stringr, tibble, tidyr
library(rvest)     # installed but not loaded by {tidyverse}

dir.create("data", showWarnings = FALSE)
dir.create("html", showWarnings = FALSE)

# ==============================================================================
# DATA :: PARTICIPANTS
# ==============================================================================

y <- c(
  "https://www.afsp.info/congres/congres-2019/index/",
  "http://www.afsp.info/congres/congres-2017/index/",
  "http://www.afsp.info/archives/congres/congres2015/indexcongres.html",
  "http://www.afsp.info/archives/congres/congres2013/indexducongres.html",
  "http://www.afsp.info/archives/congres/congres2011/programme/index.html",
  "http://www.afsp.info/archives/congres/congres2009/programmes/indexnoms.html"
)

d <- tibble::tibble()

cat("[PARSING] participant indexes for", length(y), "conferences:\n\n")
for (i in y) {
  
  f <- str_c("html/", str_extract(i, "\\d{4}"), "_participants.html")
  if (!file.exists(f)) {
    download.file(i, f, mode = "wb", quiet = TRUE)
  }
  
  cat("", f)
  f <- readr::read_lines(f) %>% 
    # [NOTE] panel abbreviations:
    #
    # AD   : atelier (2013, 2015, 2017)
    # CONFERENCE : conference, followed by « quoted title » (2019) ; replaces CP
    # CP   : plenary conference, not always numbered (2009--2017)
    # MD   : module (2009)
    # MDFB : module (2015)
    # MPP  : module (2013)
    # MTED : module (2015)
    # ST : panel ('section thématique'), all editions
    # ... sometimes numbered as in DD.D: 12.1, 12.2 (2009)
    # ... sometimes with non-numeric names (tied to research groups):
    #   - 'ST RC20IPSA', 'ST PopAct' (2015)
    #   - 'ST EpoPé', 'ST FoLo', 'ST GrUE', 'ST SPoC' (2019)
    #   - 'ST GA « ... »' (2019)
    #
    # TR: roundtable ('table ronde')
    # - a single, unnumbered TR from 2013 is unlisted and thus ignored
    # - a single, unnumbered TR from 2015 is listed and thus captured
  str_subset(
    str_c(
      "(AD|CP|MD|MPP|MTED|ST)\\s?",
      "(\\d|EpoPé|FoLo|GA|GRAM|GrePo|GrUE|PopAct|RC|SPoC)",
      "|\\s(MDFB|CP)|Conférence «"
    )
  ) %>%
    # transliterate, using sub to keep strings with non-convertible bytes
    iconv(to = "ASCII//TRANSLIT", sub = " ") %>%
    # remove diacritics
    str_remove_all("[\"^'`~\\.]|&#8217;|&(l|r)squo;") %>%
    # remove loose HTML tags
    str_remove_all("<br\\s?/?>|<(p|b|li|span)(.*?)>|</(p|b|li|span)>") %>%
    # remove French/Spanish name particles
    str_remove_all(regex("\\s\\(d(a|e)\\)", ignore_case = TRUE)) %>%
    # fix spaces (keep before next)
    str_replace_all("(\\s|&nbsp;)+", " ") %>% 
    # &eacute, &icirc -> e, i
    str_replace_all("&(\\w{1})(.*?);", "\\1") %>% 
    # lone initials within name
    str_replace_all("\\s[A-Za-z]{1}\\s", " ") %>% 
    # lone initials at end of name + extra spaces
    str_replace_all("(\\s[A-Za-z])+,|\\s+,", ",") %>% 
    str_trim() %>% 
    tibble::tibble(year = str_extract(f, "\\d{4}"), i = .)
  
  cat(":", nrow(f), "lines\n")
  d <- bind_rows(d, f)
  
}

# [2019] solve one problematic case (two lines on one)
d <- filter(d, i != "LEVY Simon ST 2 LHERVIER Louise ST 56") %>% 
  bind_rows(
    .,
    tibble::tribble(
      ~ year, ~ i,
      "2019", "LEVY Simon ST 2",
      "2019", "LHERVIER Louise ST 56"
    )
  )

# make sure that every row has at least one comma
#
# [2019] amendments:
#
# - [A-Z] (e.g. 'FAURE Samuel BH ST GrUE')
# - 'Conférence'
# - l?ST (n = 1 case)
#
d$i <- str_replace(
  d$i,
  "([A-Za-z]+)\\s(AD|Conference|CP|MD|MPP|MTED|l?ST|TR)",
  "\\1, \\2"
) %>% 
  str_to_upper()

# hard-coded manual corrections (n = 1 in each case)
#
# [2009] 'ST, 39,'
d$i <- str_replace(d$i, "ST,\\s39,", "ST 39,")
# [2011] 'ST 44,'
d$i <- str_remove(d$i, ",$")
# [2013] 'PILLON, JEAN-MARIE'
d$i <- str_replace(d$i, "^PILLON,\\sJ", "PILLON J")
# [2015] 'LENGUITA, PAULA'
d$i <- str_replace(d$i, "^LENGUITA,\\sP", "LENGUITA P")
# [2019] 'LE, TRIVIDIC'
d$i <- str_replace(d$i, "^LE,\\s(.*)\\sLILA\\s", "LE \\1 LILA, ")
# [2019] 'MORO, FRA...'
d$i <- str_replace(d$i, "^MORO,\\s", "MORO ")
# [2019] 'LST' -> 'ST' 
d$i <- str_replace(d$i, ",\\sLST\\s65", ", ST 65")
# [2019] 'ST 46 V' and 'ST 19 C'
d$i <- str_replace(d$i, "ST\\s(\\d{2})\\s\\w{1}$", "ST \\1")

# rows with ';' are all false positives, as are rows without ','
d <- filter(d, str_detect(i, ","), !str_detect(i, ";|^\\("))

# [NOTE] real counts for comparison (established by hand):
#
# 2009 =  725 (got all)
# 2011 =  632 (got all)
# 2013 =  862 (got all)
# 2015 =  872 [!!!] [NOTE] missing 2, not sure why
# 2017 =  756 [!!!] [NOTE] missing 2, not sure why
# 2019 = 1020 (got all; [NOTE] two cases on same line, solved earlier)
#
cat("\nParticipants per conference:\n")
print(table(d$year))

# how many attendees went to a single conference?
table(d$year, str_count(d$i, ","))

# [2019] commas in some panel titles need to be removed before splitting
#        'ST GA [or] CONFERENCE << X, Y ET Z >>'
str_extract_all(d$i, "(\\w+\\s)?\\w+\\s<<(.*?)>>") %>%
  unlist() %>%
  table()

# [NOTE] in one case, the participant has attended more than one ST GA
filter(d, str_count(i, "ST GA") > 1)

# later on, when we download panels, we save the files under their basename,
# stripped of '-' dashes and '.html' -- so we need to do the same thing here,
# to match data from the participants index page to that from the panel pages
#
# "https://www.afsp.info/congres/congres-2019/sections-thematiques/" %>%
#   read_html() %>%
#   html_nodes(xpath = "//a[contains(@href, '-ga-')]") %>%
#   html_attr("href") %>%
#   basename()

# load corrected titles (no commas or spaces)
# corrections include CONFERENCE titles, even though we do not use them later
a <- read_tsv("data/panels_fixes.tsv", col_types = "cc")

for (i in 1:nrow(a)) {
  # cat(a$title[ i ], "->", a$titled_fixed[ i ], "\n")
  d$i <- str_replace_all(d$i, a$title[ i ], as.character(a$title_fixed[ i ]))
}

# [NOTE] the loop can be replaced with `purrr::walk2` (1), but only by calling
#        `assign` and `get` in ugly ways (1, 2), so not doing that
#
# [1]: https://stackoverflow.com/a/62879125/635806
# [2]: https://stackoverflow.com/a/15670409/635806

# ==============================================================================
# EDGES
# ==============================================================================

# sanity check: only single spaces in the string to split
stopifnot(!str_detect(d$i, "\\s{2,}"))

# coerce to (year, i, j) data frame
d <- d %>%
  tidyr::separate(i, c("i", "j"), ",\\s?", extra = "merge", remove = FALSE) %>%
  mutate(j = str_split(j, ",\\s?")) %>%
  unnest(j)

# add year to panel ids
d$j <- str_c(d$year, "_", str_remove_all(d$j, "\\s+")) # j ~ '2009_ST46'
stopifnot(!str_detect(d$j, "\\s"))

# [2019] single-number panels from that year have a trailing zero in the URL
#        of their panel Web page
d$j <- str_replace(d$j, "^2019_ST(\\d)$", "2019_ST0\\1")

# ==============================================================================
# FINALIZE
# ==============================================================================

# finalize participant names

# (1) remove multiple spaces
d$i <- str_replace_all(d$i, "\\s+", " ")

# (2) fix some problematic names using names.tsv
# - some caused by extra comma between first and last names
# - some caused by name inversions, esp. among foreigners
# - some caused by typos, e.g. double consonants
f <- readr::read_tsv("data/participants_names.tsv", col_types = "ccc")

# sanity check: no extraneous names
stopifnot(f$i %in% d$i)

d <- left_join(d, f, by = c("year", "i")) %>% 
  mutate(i = if_else(is.na(i_fixed), i, i_fixed)) %>% 
  select(-i_fixed)

# # to detect (several forms of, but not all) errors:
#
# (1) duplicated words in name
#
# str_split(d$i, " ") %>% sapply(function(x) x[1] == x[2]) %>% which
# str_split(d$i, " ") %>% sapply(function(x) x[1] == x[3]) %>% which
# str_split(d$i, " ") %>% sapply(function(x) x[2] == x[3]) %>% which
#
# (2) names with only 1 or 2 different letters:
# library(stringdist)
# for(i in unique(d$i)) {
#   m <- stringdist::stringdist(i, unique(d$i))
#   m <- which(m > 0 & m < 3)
#   if (length(m) > 0)
#     cat(i, ":", str_c("\n ~ ", unique(d$i)[ m ]), "\n\n")
# }

# no remaining problematic rows
stopifnot(str_detect(d$i, "\\s"))

# finalize panel names

# fix sessions with no type (n = 2, both 2009, both are ST)
d$j <- str_replace(d$j, "_(\\d+)$", "_ST\\1")

# fix sessions with an extra comma between type and id (one case in 2009)
d$j <- str_replace(d$j, "ST, (\\d+)$", "_ST\\1")

# finalize rows by handling special cases (all detected manually)

f <- readr::read_tsv("data/participants_fixes.tsv", col_types = "ccc")
stopifnot(f$type %in% c("abs", "add", "err"))

# (1) remove participants with wrong names, wrong panel entries, or both; the
#     list contains participants confused with other participants or assigned
#     to the wrong panel; the correct information are added in the next step

d <- anti_join(d, filter(f, type == "err"), by = c("i", "j"))

# (2) add participants completely omitted from the indexes or that correct some
#     of the rows just removed (see note above); after that step, the list of
#     participants and panels listed in d (edges) should match participants.tsv

d <- filter(f, type == "add") %>% 
  mutate(year = str_sub(j, 1, 4)) %>% 
  select(year, i, j) %>% 
  bind_rows(d) %>% 
  arrange(year, i, j) # (not really needed)

# almost done (1/2): if participants.tsv already exists, check that the edges
#                    collected in d match its contents (including absentees)

p <- "data/participants.tsv"
if (file.exists(p)) {
  
  p <- readr::read_tsv(p, col_types = "cccc")
  
  # match absentees in participants.tsv (source: panels)
  # to absentees in fixes.tsv (source: indexes)
  
  f <- filter(p, role == "a") %>%  # absentees, participants.tsv
    anti_join(filter(f, type == "abs"), by = c("i", "j")) # absentees, fixes.tsv
  
  stopifnot(!nrow(f)) # all rows should have been matched
  
  # match participants in participants.tsv (source: panels)
  # to participants in d (source: indexes)
  
  f <- anti_join(p, d, by = c("i", "j"))
  
  stopifnot(!nrow(f)) # all rows should have been matched
  
}

# almost done (2/2): check that panels with less than 2 participants are not
#                    not panels but special events (plenary conferences and
#                    workshops) with a single announced participant/speaker

group_by(d, year, j) %>% 
  mutate(n_j = n()) %>% 
  filter(n_j == 1)

# ==============================================================================
# COUNTS
# ==============================================================================

# how many participations over the 5 conferences?
t <- group_by(d, i) %>% 
  summarise(t_c = n_distinct(year)) %>% 
  arrange(-t_c)

table(t$t_c) # 24 participants went to all conferences, ~ 2,100+ went to only 1
table(t$t_c > 1) / nrow(t) # ~ 70% attended only 1 of 6 conferences in 10 years

# number of panels overall
n_distinct(d$j)

# number of panels in each conference
cat("\nPanels per conference:\n\n")
print(tapply(d$j, d$year, n_distinct))

# add number of panels attended per conference
# (useful for edge weighting)
d <- group_by(d, year, i) %>% 
  summarise(n_p = n()) %>% 
  inner_join(d, ., by = c("year", "i"))

# add total number of panels attended and total number of conferences attended
# (useful for vertex subsetting)
d <- group_by(d, i) %>% 
  summarise(t_p = n_distinct(j), t_c = n_distinct(year)) %>% 
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
p <- readr::read_tsv(f, locale = p, col_types = "iccd", progress = FALSE) %>% 
  filter(preusuel != "_PRENOMS_RARES", str_count(preusuel) > 2) %>% 
  mutate(preusuel = iconv(preusuel, to = "ASCII//TRANSLIT", sub = " ") %>%
           # remove diacritics
           str_remove_all("[\"^'`~\\.]|&#8217;|&(l|r)squo;")) %>%
  group_by(preusuel) %>% 
  summarise(p_f = sum(nombre[ sexe == 2 ]) / sum(nombre)) %>% 
  rename(first_name = preusuel)

a <- select(d, year, i, j) %>% 
  distinct()

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
f <- "data/participants_genders.tsv"
p <- readr::read_tsv(f, col_types = "cc") %>% 
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
  str_remove(a$i, a$first_name) %>% 
    str_trim()
)

# sanity check
stopifnot(!is.na(a$family_name))

cat(
  "\n[MISSING] First names of",
  n_distinct(a$i[ is.na(a$first_name) ]),
  "participants(s)\n"
)

# ==============================================================================
# FINALIZE GENDERS
# ==============================================================================

# missing less than 100 missing values
a$gender <- recode(a$p_f, `1` = "f", `0` = "m", .default = NA_character_)

# # for manual checks:
# filter(a, !p_f %in% c(0, 1)) %>% View

# save manually collected values, with missing values back again
w <- unique(a$i[ is.na(a$gender) ])
if (length(w) > 0) {
  
  tibble::tibble(gender = NA_character_, name = w) %>% 
    bind_rows(p) %>% 
    arrange(name) %>% 
    readr::write_tsv(f)
  
}

cat("[MISSING] Gender of", n_distinct(w), "participant(s)\n")

# sanity check: all rows in genders.tsv exist in participants data
stopifnot(readr::read_tsv(f, col_types = "cc")$name %in% unique(a$i))

# ==============================================================================
# EXPORT PARTICIPANTS TO TSV
# ==============================================================================

readr::write_tsv(
  select(a, -found_name, -p_f) %>% 
    left_join(d, ., by = c("year", "i", "j")) %>% 
    arrange(year, i, j),
  "data/edges.tsv"
)

cat(
  "\n[SAVED]",
  nrow(d),
  "rows,", 
  n_distinct(d$i),
  "participants,",
  n_distinct(d$j),
  "panels."
)

# ==============================================================================
# DATA :: PANELS
# ==============================================================================

y <- str_c(
  "https://www.afsp.info/",
  c(
    "congres/congres-2019/sections-thematiques/",
    "congres/congres-2017/sessions/sections-thematiques/",
    "archives/congres/congres2015/st.html",
    "archives/congres/congres2013/st.html",
    "archives/congres/congres2011/sectionsthematiques/presentation.html",
    "archives/congres/congres2009/sectionsthematiques/presentation.html"
  )
)

# initialize panels data
d <- tibble::tibble()

cat("\n\n[PARSING] 'ST' panel indexes for", length(y), "conferences:\n\n")
for (i in y) {
  
  f <- str_c("html/", str_extract(i, "\\d{4}"), "_panels.html")
  if (!file.exists(f)) {
    download.file(i, f, mode = "wb", quiet = TRUE)
  }
  
  cat("", f)
  f <- read_html(f) %>% 
    html_nodes(xpath = "//a[contains(@href, 'st')]")
  
  j <- str_c("ancestor::", if_else(str_detect(i, "201[79]"), "p", "li"))
  
  # special cases below are all for [2015],
  # except 'ga-(.*)', 'folo', 'grue' and 'spoc`, which are for [2019]
  w <- str_which(
    html_attr(f, "href"),
    str_c(
      "st(-|\\d|ga-(.*)|epope|folo|grue|spoc|gram|grepo|popact|rc20ipsa)+",
      "(\\.html|/$)"
    )
  )
  w <- tibble::tibble(
    year = as.integer(str_extract(i, "\\d{4}")),
    url = html_attr(f[ w ], "href"),
    id = basename(url) %>%
      str_remove_all(".html|-") %>%
      str_to_upper(), # matches ids in edges.tsv and panels.tsv
    title = html_nodes(f[ w ], xpath = j) %>% 
      html_text(trim = TRUE) %>% 
      str_remove("^ST[\\.\\s\\d/-]+") # redundant with (cleaner) panels.tsv
  )
  
  # fix relative URLs
  w$url <- if_else(
    str_detect(w$url, "^http"),
    w$url,
    str_c(dirname(i), "/", w$url)
  )
  
  # avoid 'empty id' mistakes that would overwrite indexes!
  stopifnot(!str_detect(w$id, "st$"))
  
  cat(":", nrow(w), "ST panels\n")
  d <- bind_rows(d, w)
  
}

# [2017] fix mismatch in panel URL / id for n = 1 case
d$id[ str_detect(d$url, "st2-2") ] <- "ST2"

# save only if the cleaner file does not exist
# [NOTE] cleaner panels.tsv also includes 'panels' that are not parsed for
#        participants (e.g. AD, CP, etc.)
f <- "data/panels.tsv"
if (!file.exists(f)) {
  readr::write_tsv(d, f)
}

# ==============================================================================
# DOWNLOAD PANEL PAGES
# ==============================================================================

# approx. 411 files (quick enough)
cat("\n[DOWNLOADING]", nrow(d), "panel pages\n")

for (i in 1:nrow(d)) {
  
  f <- str_c("html/", d$year[ i ], "_", d$id[ i ], ".html")
  
  if (!file.exists(f)) {
    download.file(d$url[ i ], f, mode = "wb", quiet = TRUE)
  }
  
}

# note: one ST panel of 2015 is missing because it was canceled/postponed

# ==============================================================================
# PREPARE PARTICIPANTS AND PANELS DATA
# ==============================================================================

# reduce participants to unique conference year-participant-panels tuples
#
# [NOTE] drop non-standard (ST) panels:
# - keeps only abstract-based panels: ST, ST GA ... (2019), 'ST EPOPE' (2019)
# - removes all special, not abstract-based panels: 'AD', CP', 'MD', 'TR' etc.
#   (those are assembled differently, with e.g. invited guests)
#
a <- filter(a, str_detect(j, "ST")) %>% 
  select(year, i, j, first_name, family_name) %>% 
  distinct() %>% 
  mutate(
    affiliation = if_else(
      is.na(first_name),
      family_name,
      str_c(
        first_name, "[\\s\\w]+?", family_name, "|", 
        family_name, "[\\s\\w]+?", first_name
      )
    ),
    role = NA # organiser or presenter (other roles need to be hand-coded)
  )

# create panel uid
d$j <- str_c(d$year, "_", d$id)

# ==============================================================================
# EXTRACT NAMES AND AFFILIATIONS
# ==============================================================================

cat("\n[PARSING]", n_distinct(d$j), "panels\n")

for (i in unique(d$j)) {
  
  f <- str_c("html/", i, ".html")
  
  # trying to find participants or separator between organisers and presenters
  t <- "//*[contains(text(), '(') or contains(text(), 'tation scientifique')]"
  t <- read_html(f) %>% 
    html_nodes(xpath = t) %>% 
    html_text() %>% 
    str_to_upper() %>% 
    iconv(to = "ASCII//TRANSLIT", sub = " ") %>%
    # remove diacritics
    str_remove_all("[\"^'`~\\.]") %>%
    # composed names + handle multiple spaces
    str_replace_all( "-|\\s+", " ") %>% 
    str_trim()
  
  # keep only strings likely to match a name and affiliation
  w <- str_count(t) > 2 & str_count(t) < 5000
  t <- t[ (t == "PRESENTATION SCIENTIFIQUE" | str_detect(t, "\\s")) & w ]
  
  # pointer separating panel organisers from presenters
  w <- max(which(t == "PRESENTATION SCIENTIFIQUE"))
  
  # two special cases omitted (produce WARNINGs because `w` is set to -Inf)
  stopifnot(
    is.integer(w) |
      str_detect(f, "2019_(STGAVIOLENCESETCONFLITS|STSPOC)")
  )
  
  # exclude everything after last affiliation
  t[ -w ] <- str_extract(t[ -w ], "(.*)\\)")
  
  # extract role
  a$role[ a$j == i ] <- map_int(
    a$affiliation[ a$j == i ],
    ~ str_which(t, .x)[ 1 ]
  ) < w # returns TRUE (organisers) or FALSE (others)
  
  # extract affiliation
  a$affiliation[ a$j == i ] <- map_chr(
    a$affiliation[ a$j == i ],
    # let's also try to identify presidents (chairs) and discussants
    # [NOTE] horrendous code, but works
    ~ t[ str_which(t, .x)[ 1 ] ] %>%
      str_extract(
        str_c(
          "(DISCUTANT-?E?-?S?|PRESIDENT-?E?-?S?)?( DE SEANCE)?(\\s+:\\s+)?(",
          .x,
          ")(.*?)\\)"
        )
      )
  )
  
}

# coerce logical organiser or presenter role (with precedence to the former)
a$role <- if_else(a$role, "o", "p")

# identify discussants
a$role[ which(a$role == "p" & str_detect(a$affiliation, "^DISCUTANT")) ] <- "d"
a$role[ which(a$role == "p" & str_detect(a$affiliation, "^PRESIDENT")) ] <- "c"
# # uncomment to detect multiple chairs/discussants for manual fixing
# a$plural <- str_detect(a$affiliation, "S :")

# remove chair/discussant prefixes
w <- "^(DISCUTANT-?E?-?S?|PRESIDENT-?E?-?S?)?( DE SEANCE)?(\\s+:\\s+)?"
a$affiliation <- str_remove(a$affiliation, w)

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
a$affiliation[ w ] <- str_remove(
  a$affiliation[ w ],
  str_c(a$first_name[ w ], " ", a$family_name[ w ])
)

a$affiliation <- str_replace_all(a$affiliation, "\\s+", " ") %>% 
  str_trim()

# # some participants have had a lot of different affiliations...
# # ... because the data are super-noisy (e.g. 'X and Y, <affil.>')
# group_by(a, i) %>%
#   summarise(n_a = n_distinct(affiliation)) %>%
#   arrange(-n_a)

# ==============================================================================
# EXPORT ROLES AND AFFILIATIONS
# ==============================================================================

a <- select(a, role, i, j, affiliation) %>% 
  arrange(i, j)

# sanity check: all rows are distinct
stopifnot(nrow(distinct(a)) == nrow(a))

# initialize file if missing
f <- "data/participants.tsv"
if (!file.exists(f)) {
  readr::write_tsv(a, f)
}

# ==============================================================================
# REVISE NAMES
# ==============================================================================

# some names in the panel pages contain errors and/or have been modified so as
# to create cross-year identities for 'x marie' and 'x-y marie' when those are
# the same persons; some names need two corrections, one in the participants
# index and one in the panel pages, because they were misspelt in both sources
d <- readr::read_tsv("data/participants_names.tsv", col_types = "ccc")

# sanity check: no extraneous names in -corrected- names
stopifnot(d$i_fixed %in% a$i)

cat("\n[REPLACED]", sum(a$i %in% d$i), "name(s)\n")

a <- left_join(mutate(a, year = str_sub(j, 1, 4)), d, by = c("year", "i")) %>% 
  mutate(i = if_else(is.na(i_fixed), i, i_fixed)) %>% 
  select(-year, -i_fixed)

# # debug with the following line
# a[ !a$i %in% readr::read_tsv(f, col_types = "cccc")$i, ] %>% print

# ==============================================================================
# REVISE ROLES AND AFFILIATIONS
# ==============================================================================

# participants.tsv columns are marked .y
p <- full_join(a, readr::read_tsv(f, col_types = "cccc"), by = c("i", "j"))

# sanity check: all 'ST' panel affiliations are covered by participants.tsv
stopifnot(!length(p$i[ !(p$i %in% a$i | !str_detect(p$j, "ST")) ]))

# count affiliations per participant and per conference year
w <- mutate(p, year = str_sub(j, 1, 4)) %>%
  filter(str_detect(j, "_ST")) %>% 
  group_by(year, i) %>%
  summarise(n_aff = n_distinct(affiliation.y)) %>%
  filter(n_aff > 1)

# sanity check: participants have only one affiliation per conference year in
# the -- manually corrected -- participants.tsv file
stopifnot(!nrow(w))

# replace empty roles with existing ones in participants.tsv
w <- which(is.na(p$role.x) & !is.na(p$role.y))
p$role.x[ w ] <- p$role.y[ w ]
cat("\n[REPLACED]", length(w), "missing role(s)\n")

# replace 'raw' roles with revised ones in participants.tsv
w <- which(p$role.x != p$role.y)
p$role.x[ w ] <- p$role.y[ w ]
cat("[REPLACED]", length(w), "revised role(s)\n")

# ==============================================================================
# REVISE AFFILIATIONS
# ==============================================================================

# replace empty affiliations with existing ones in participants.tsv
w <- which(is.na(p$affiliation.x) & !is.na(p$affiliation.y))
p$affiliation.x[ w ] <- p$affiliation.y[ w ]
cat("\n[REPLACED]", length(w), "missing affiliation(s)\n")

# replace 'raw' affiliations with revised ones in participants.tsv
w <- which(p$affiliation.x != p$affiliation.y)
p$affiliation.x[ w ] <- p$affiliation.y[ w ]
cat("[REPLACED]", length(w), "revised affiliation(s)\n")

f <- "data/edges.tsv"
p <- rename(p, role = role.x, affiliation = affiliation.x) %>% 
  select(i, j, role, affiliation) %>% 
  full_join(readr::read_tsv(f, col_types = "icciiiiccc"), ., by = c("i", "j"))

cat("\nDistinct participants:\n\n")
tapply(p$i, p$year, n_distinct) %>%
  print()

cat("\nNon-missing participants:\n\n")
tapply(p$i, p$year, function(x) sum(!is.na(x), na.rm = TRUE)) %>%
  print()

cat("\nDistinct affiliations:\n\n")
tapply(p$affiliation, p$year, n_distinct) %>%
  print()

cat("\nNon-missing affiliations:\n\n")
tapply(p$affiliation, p$year, function(x) sum(!is.na(x), na.rm = TRUE)) %>%
  print()

cat("\nPercentages of non-missing affiliations:\n\n") # always above 90%
f <- function(x) { 100 * sum(!is.na(x), na.rm = TRUE) }
round(tapply(p$affiliation, p$year, f) / table(p$year)) %>%
  print()

# ==============================================================================
# FINAL CHECKS AND EXPORT
# ==============================================================================

cat(
  "\n[SAVED]",
  nrow(p),
  "rows,", 
  n_distinct(p$i),
  "participants,",
  n_distinct(p$j),
  "panels,",
  n_distinct(p$affiliation),
  "affiliations.\n"
)

# # only two panels (from 2009) have a single organiser
# group_by(p, j) %>%
#   summarise(n_o = sum(role == "o")) %>%
#   filter(is.na(n_o) | n_o < 2, str_detect(j, "ST"))

# # top affiliations (imprecise: ignores multiple affiliations)
# group_by(p, affiliation) %>%
#   tally(sort = TRUE)

# panels with no missing data in affiliations
with(
  filter(p, !is.na(affiliation)),
  table(str_remove_all(j, "\\d|_"), str_extract(j, "\\d+"))
)

# panels with missing affiliations (expected for many: not parsed)
with(
  filter(p, is.na(affiliation)),
  table(str_remove_all(j, "\\d|_"), str_extract(j, "\\d+"))
)

# add affiliations and roles only if need be
readr::write_tsv(select(p, -affiliation, -role), "data/edges.tsv")

# kthxbye
