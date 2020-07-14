> __Important notice:__ the following datasets contain personal data taken from the [AFSP](http://www.afsp.info/) website. The data have been compiled for research purposes only. According to [French law](https://www.cnil.fr/comprendre-vos-droits), you can ask the maintainer of the data for [access](https://www.cnil.fr/fr/le-droit-dacces), [rectification](https://www.cnil.fr/fr/le-droit-de-rectification) or even [suppression](https://www.cnil.fr/fr/le-droit-dopposition) of the data (although the latter requires 'legitimate' reasons to do so). To exercise any of those rights, please [email me](mailto:francois.briatte@sciencespo.fr).

All files documented below are UTF-8 encoded. All values are unquoted, and missing values are coded as `NA`. None of the files should contain any duplicated rows.

## [`edges.tsv`][data-edges]

A TSV file with one row per conference participant and per conference panel attended:

- `year` – Year of AFSP conference ([2009][2009], [2011][2011], [2013][2013], [2015][2015], [2017][2017], [2019][2019]).
- `i` – Full name of the participant, coded as `FAMILY NAME FIRST NAME`, all uppercase, without accents or lone initials, and sometimes harmonised to allow for matching across conference years.
- `j` – Panel attended, coded as `YEAR_ID`, where `ID` contains the type of panel (e.g. `CP` for plenary conferences, `ST` for thematic sessions), followed by the alphanumeric identifier of the panel when there was one.
- `n_j` – Number of participants to the conference panel.
- `n_p` – Number of conference panels attended that year by the participant.
- `t_p` – Total number of panels attended by the participant.
- `t_c` – Total number of conferences attended by the participant.
- `first_name` – First name(s) of the participant, extracted from `i`.
- `family_name` – Family name of the participant, extracted from `i`.
- `gender` – Gender of the participant, coded as `f` for female and `m` for male.

__Note__ – The `gender` variable is based on sex ratios computed from the [_Fichier Prénoms Insee_, 2016 edition][data-prenoms], which will be downloaded to the `data` folder during data preparation, as well as on manual additions provided in [`participants_genders.tsv`][data-genders].

[data-edges]: https://github.com/briatte/congres-afsp/blob/master/data/edges.tsv
[data-prenoms]: https://www.insee.fr/fr/statistiques/2540004
[2009]: http://www.afsp.info/archives/congres/congres2009/programmes/indexnoms.html
[2011]: http://www.afsp.info/archives/congres/congres2011/programme/index.html
[2013]: http://www.afsp.info/archives/congres/congres2013/indexducongres.html
[2015]: http://www.afsp.info/archives/congres/congres2015/indexcongres.html
[2017]: http://www.afsp.info/congres/congres-2017/index/
[2019]: https://www.afsp.info/congres/congres-2019/

## [`incidence_matrix.rds`][data-incidence_matrix]

A serialized R object of class `matrix` representing the _i_ (conference participant) &times; _j_ (conference panel) incidence matrix contained in [`edges.tsv`][data-edges], with each edge inversely weighted by 1 / _n<sub>j</sub>_, where _n<sub>j</sub>_ denotes the total number of participants to panel _j_. Because all conference panels have at least two participants, the edge weights have a maximum value of 0.5.

[data-incidence_matrix]: https://github.com/briatte/congres-afsp/blob/master/data/incidence_matrix.rds

## [`panels.tsv`][data-panels]

A TSV (tab-separated) file with one row per conference panel:

- `year` – Year of AFSP conference.
- `id` – Panel identifier that matches the `ID` part of the `j` variable in [`edges.tsv`][data-edges].
- `title` – Panel title, slightly cleaned up:
  - Multiples spaces were replaced by a single one.
  - Double quotes are coded as `«` French quotes `»`.
  - Single quotes are coded as `’`.
  - Unbreakable spaces are used before `:;?!` and before/after double quotes.
  - Full stops at the end of titles were removed.
  - All instances of `État` (the State) are accentuated.
- `notes` – Notes, in French, when available (e.g. to indicate the panel was postponed).

The data were manually extracted from the relevant [AFSP Web pages](http://www.afsp.info/congres/editions-precedentes/). A handful of panels listed in the file have no participants listed in [`edges.tsv`][data-edges], for various reasons (e.g. the panel was cancelled or postponed, the panel is a PhD workshop with no participants list).

This file contains slightly better formatted panel titles than those collected during data preparation, and should therefore be preferred when requesting that information. The information contained in the `notes` column are exclusive to that file.

[data-panels]: https://github.com/briatte/congres-afsp/blob/master/data/panels.tsv

## [`panels_fixes.tsv`][data-panels-fixes]

A TSV (tab-separated) file that removes special characters (commas especially) from the names of some special panels (group-specific thematic panels or conferences) present in the 2019 data.

- `title` – `<<` Quoted `>>` title of the panel.
- `title_fixed` – Cleaned up panel title.

[data-panels-fixes]: https://github.com/briatte/congres-afsp/blob/master/data/panels_fixes.tsv

## [`participants.tsv`][data-participants]

A TSV (tab-separated) file with one row per conference participants and per conference panel attended (see [`edges.tsv`][data-edges] below):

- `role` – Role of the participant within the panel:
  - Programmatically identified roles: `o` (organiser), `p` (presenter); those roles are the only ones that can be trusted to be somewhat reliably coded for most panels. In particular, all panels with less than two organisers have been manually checked and corrected when needed.
  - Manually identified roles: `c` and `d` (chair or discussant who is not also a presenter), `a` (absentee, i.e. participant listed in the conference index but not listed anywhere in the panel page).
  - The role is coded as `e` (for "else") if the participant is listed at the end of the panel page but does not appear anywhere else on the page.
- `i` – Full name of the participant, coded exactly as `i` in [`edges.tsv`][data-edges].
- `j` – Panel attended, coded exactly as `j` in [`edges.tsv`][data-edges].
- `affiliation` – Academic affiliation, standardized to a reasonable level:
  - When available, the affiliation starts with the acronym or name of the research unit, which might be a department, an institute, a research laboratory or team, etc. Merged units contain both names separated by dashes, e.g. `GSPE-PRISME-SAGE`.
  - The affiliation then usually contains the name of the university or other institution that hosts the research unit. All linguistic variants of the word "university" are replaced with `U.`, and Parisian universities are denoted by their [post-1968 number](https://fr.wikipedia.org/wiki/Universit%C3%A9_de_Paris#D.C3.A9membrement_de_l.27universit.C3.A9_de_Paris) in Arabic form (e.g. `"U. PARIS 11"`). Some units are co-hosted by several institutions separated with ampersands and/or dashes, e.g. `IEP-U. STRASBOURG` or `ENS-PARIS & EHESS PARIS`.
  - When the institution is located in France, an effort is made to include the city in its name, e.g. `INSEEC BORDEAUX`. When the institution is located outside of France, the country is indicated in brackets, in French, at the exception of `USA`. This also applies to some French institutions located abroad, and does _not_ apply to the American University in Paris.
  - Non-academic affiliations, which can be either institutions (e.g. `"UNESCO"`), or occupations (e.g. `"consultant"`), are surrounded by `[`hard brackets`]` and might include a geographic indication (see previous point).
  - All other information (irregularly) reported in the raw data have been removed, including, for instance, CNRS, FNRS and IUF affiliations, memberships to informal research groups or to funded projects (e.g. ANR, ERC, LABEX), and doctor or professor titles.
  - Multiple affiliations are listed by their original order of appearance and are separated with slashes, as in `x, y (z) / a, b` (in this example, the first affiliation is from an institution located outside of France).

Although an effort has been made to harmonize affiliations, many of the affiliations listed in this file are either lowly accurate, incomplete, or missing entirely.

This file can be manually revised to improve the accuracy of the `affiliation` variable in [`edges.tsv`][data-edges]. Its `role` variable will get copied to [`edges.tsv`][data-edges] during data preparation.

[data-participants]: https://github.com/briatte/congres-afsp/blob/master/data/participants.tsv

## [`participants_fixes.tsv`][data-participants-fixes]

A TSV (tab-separated) file with one row per conference participant and per conference panel attended for which a fix was identified by manually checking the original data, and therefore to be used to fix errors in [`edges.tsv`][data-edges]:

- `type` – type of fix to perform:
  - `add`: append this row (i.e. the participant is entirely missing from the [`edges.tsv`][data-edges], i.e. from participant indexes)
  - `err`: remove the row ("error" found either in the panel identifier, and/or in the identity of the participant)
  - `abs`: remove or ignore prior to analysis, depending on analytical strategy; indicates that the participant has been manually confirmed as absent (i.e. unlisted) from the panel data, which should match value `a` in variable `role` in [`participants.tsv`][data-participants]
- `i` – Full name of the participant, either coded exactly as `i` in [`edges.tsv`][data-edges] or corrected for misspellings and other errors.
- `j` – Panel attended, coded exactly as `j` in [`edges.tsv`][data-edges].

[data-participants-fixes]: https://github.com/briatte/congres-afsp/blob/master/data/participants_fixes.tsv

## [`participants_genders.tsv`][data-genders]

A TSV (tab-separated) file with one row per conference participant present in [`edges.tsv`][data-edges] for which gender could not be determined from the [_Fichier Prénoms Insee_, 2016 edition][data-prenoms] (see note above):

- `gender` – Gender of the participant:
  - Coded as `f` for female and `m` for male.
  - All missing values so far have been manually inputed.
- `name` – Full name of the participant, coded exactly as `i` in [`edges.tsv`][data-edges].

This file can be manually revised to improve the completeness of the `gender` variable in [`edges.tsv`][data-edges]. The file will be loaded during data preparation, updated with any new participant names for which gender could not be determined, and then re-saved.

[data-genders]: https://github.com/briatte/congres-afsp/blob/master/data/participants_genders.tsv

## [`participants_names.tsv`][data-names]

A TSV (tab-separated) file with one row per participant present in [`edges.tsv`][data-edges] for which the name needed to be manually modified for any reason (usually typos or inconsistencies across conference years):

- `year` – Year of AFSP conference.
- `i` – Full name of the participant, as found in the original data.
- `i_fixed` – Corrected full name of the participant, coded exactly as `i` in [`edges.tsv`][data-edges].

__Note__ – The corrections apply the simplifications listed in the documentation for [`edges.tsv`][data-edges], as well as some additional simplifications to foreign names: for instance, Korean first names (e.g. `KIL-HO` or `SUNG-EUN`) are simplified by removing the dash, as seems to have been commonly done in the original data.

[data-names]: https://github.com/briatte/congres-afsp/blob/master/data/participants_names.tsv
