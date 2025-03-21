% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SurvNet_Import.R
\name{create_Epidata}
\alias{create_Epidata}
\title{createEpidata}
\format{
The csv file written to "out" has the following columns:
\describe{
  \item{Sample ID}{Character. As "Labornummer" from LIMS}
  \item{Alias ID (s)}{Character. This is the \strong{merge key}! As
  "SurvNet.AZ" from SurvNet and as "Aktenzeichen" from LIMS.}
  \item{Zip of Isolation}{Character. As PLZ from LIMS}
  \item{IdRecord}{Character. Unchanged from SurvNet}
  \item{Collection Date}{Date. As Meldedatum from SurvNet}
  \item{Gesundheitsamt}{Character. Via merge based on
  Eigentuemer from SurvNet (merge key) obtaining the Gesundheitsamt
  variable from data("Eigentuemer")}
  \item{Meldelandkreis}{Character. Unchanged from SurvNet}
  \item{MunicipalityKey}{Character. Unchanged from SurvNet}
  \item{Host Age (years)}{Numeric. As AgeComputed from SurvNet}
  \item{Host Sex}{Character. Recoded from Geschlecht from SurvNet}
  \item{HospStatus}{Character. Recoded from HospitalisierungStatus from
  SurvNet}
  \item{VerstorbenStatus}{Character. Recoded from VerstorbenStatus from
  SurvNet}
  \item{Expositionsort}{Character. Derived from multiple exposure variables
  from SurvNet (see ?luaRlp:::.combine_exposure)}
  \item{Outbreak}{foo}
  \item{Country of Isolation}{foo}
  \item{Lat/Long of Isolation}{foo}
  \item{Project}{foo}
  \item{Host}{foo}
  \item{Source type}{foo}
  \item{Source subtype}{foo}
  \item{Specimen type}{foo}
  }
}
\usage{
create_Epidata(
  LIMS_link_file,
  out =
    paste0("O:/Abteilung Humanmedizin (AHM)/Referat 32/32_6/14_EpiDaten/LIMS Import/",
    "SurvNetExport4RIDOM", format(Sys.time(), "\%Y-\%m-\%d_\%H-\%M-\%S"), ".csv"),
  problems = NULL,
  type_of_problem = "non-matching-LIMS"
)
}
\arguments{
\item{LIMS_link_file}{The file (exported from our LIMS) associating our
LUA Probennummern (3263-) and SurvNet IDs (Aktenzeichen with licence plate
prefix)}

\item{out}{The output file in csv format (defaults to  SurvNetExport4RIDOM
plus the current timestamp wirtten into
"O:/Abteilung Humanmedizin (AHM)/Referat 32/32_6/14_EpiDaten/")}

\item{problems}{If problematic entries should be reported into a file
(a filename or path to a file) should be given. Which entries are regarded as
problematic are defined via type_of_problem}

\item{type_of_problem}{should be "non-matching-LIMS". The currently only
available option (also the current default) is to write non-matching LIMS
entries to a file (given in the argument "problems").}
}
\value{
Writes a csv file compatible with the RIDOM database scheme "LUA RLP
default bacteria to "\strong{out}" and a optionally a second csv file to
"\strong{problem}". See "Format".
}
\description{
createEpidata
}
