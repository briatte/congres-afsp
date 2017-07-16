> __Important notice:__ the following datasets contain personal data taken from the [AFSP](http://www.afsp.info/) website. The data have been compiled for research purposes only. According to [French law](https://www.cnil.fr/comprendre-vos-droits), you can ask the maintainer of the data for [access](https://www.cnil.fr/fr/le-droit-dacces), [rectification](https://www.cnil.fr/fr/le-droit-de-rectification) or even [suppression](https://www.cnil.fr/fr/le-droit-dopposition) of the data (although the latter requires 'legitimate' reasons to do so). To exercise any of those rights, please [email me](mailto:francois.briatte@sciencespo.fr).

All files documented below are UTF8-encoded, with missing values coded as `NA`.

## [`affiliations.tsv`][data-affiliations]

A TSV (tab-separated) file with one row per conference attendee and per conference panel attended (see [`edges.csv`][data-edges] below):
  
- `i` – Full name of the attendee, coded exactly as `i` in [`edges.csv`][data-edges].
- `j` – Panel attended, coded exactly as `j` in [`edges.csv`][data-edges].
- `affiliation` – Academic affiliation, standardized to some level:
  - When available, the affiliation starts with the acronym or name of the research unit, which might be a department, an institute, a research laboratory, etc.
  - The affiliation then usually contains the name of the university or other institution that hosts the research unit:
    - All linguistic variants of the word "university" are replaced with `U.`.
    - All Parisian universities are denoted by their Arabic number, e.g. `U. PARIS 10`.
  - Last, when the institution is located outside of France, the country is then indicated in brackets, in French. This also applies to some French institutions located abroad.
  - All other information (irregularly) reported in the raw data have been removed, including, for instance, CNRS and FNRS affiliations, and professor titles.
  - Non-academic affiliations are surrounded by `[`hard brackets`]`. Attendees who declared being independent consultants/researchers are coded as `[INDEPENDANT]`.
  - Multiple affiliations are listed by their original order of appearance and are separated with slashes, as in `x, y (z) / a, b` (in this example, the first affiliation is from a non-French institution).

Many of the affiliations listed in this file are either lowly accurate, incomplete, or missing entirely.

This file can be manually revised to improve the accuracy of the `affiliation` variable in [`edges.csv`][data-edges]. Its contents will get copied to [`edges.csv`][data-edges] during data preparation.

[data-affiliations]: https://github.com/briatte/congres-afsp/blob/master/data/affiliations.tsv

## [`edges.csv`][data-edges]

A CSV file with one row per conference attendee and per conference panel attended:
  
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
  - Determined from `first_name` (see note below).
- `affiliation` – Academic affiliation(s) of the attendee; see [`affiliations.tsv`][data-affiliations] above.

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
  - All, missing values so far have been manually inputed.
- `name` – Full name of the attendee, coded exactly as `i` in [`edges.csv`][data-edges].

This file can be manually revised to improve the completeness of the `gender` variable in [`edges.csv`][data-edges]. The file will be loaded, possibly updated with new attendee names for which gender could not be determined, and then re-saved during data preparation.

[data-genders]: https://github.com/briatte/congres-afsp/blob/master/data/genders.tsv

## [`incidence_matrix.rds`][data-incidence_matrix]

A serialized R object of class `matrix` representing the _i_ &times; _j_ incidence matrix contained in [`edges.csv`][data-edges], with each edge weighted by 1 / _n<sub>j</sub>_. Because all conference panels have at least two attendees, the edge weights have a maximum value of 0.5.

[data-incidence_matrix]: https://github.com/briatte/congres-afsp/blob/master/data/incidence_matrix.rds

## [`panels.tsv`][data-panels]

A TSV (tab-separated) file with one row per conference panel:
  
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

[data-panels]: https://github.com/briatte/congres-afsp/blob/master/data/panels.tsv
