% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RIDOM_pipeline_evaluation.R
\name{RIDOM_comptable_re_evaluate}
\alias{RIDOM_comptable_re_evaluate}
\title{RIDOM_comptable_re_evaluate}
\usage{
RIDOM_comptable_re_evaluate(
  old_folder,
  new_folder,
  out_folder = paste0(basename(old_folder), "_VS_", basename(new_folder), "_",
    format(Sys.time(), "\%Y-\%m-\%d_\%H-\%M-\%S"), "/"),
  wanted_cols = c("Sample ID", "Perc. Good Targets", "Avg. Coverage (Assembled)", "ST",
    "ST Warwick", "Complex Type", "N50 (Assembled)", "O Type", "H Type", "Serovar")
)
}
\arguments{
\item{old_folder}{A folder containing RIDOM comparison tables in csv format,
these should be "old", e.g. from a previously run, changed pipeline or simply
the old state of exports in a routin re-evaluation}

\item{new_folder}{A second folder containing RIDOM comparison tables in csv
format, these should be "new", e.g. from a novel changed pipeline or simply
the new state of exports in a routine re-evaluation}

\item{out_folder}{output folder for the comparison tables of old vs. new. By
default this will be set to "old_folder_VS_new_folder_timestamp/" in the
current working directory.}

\item{wanted_cols}{the columns that should be compared. Defaults to
"Sample ID", "Perc. Good Targets", "Avg. Coverage (Assembled)", "ST"
(all projects but EHEC), "ST Warwick" (project Produktiv_EHEC),
"Complex Type", "N50 (Assembled)", "O Type" (project Produktiv_EHEC),
"H Type" (project Produktiv_EHEC) and "Serovar" (project Produkiv_Salmonella)}
}
\value{
csv files are written into a folder: One file for each Assembly
(SOP), EHEC, Salmonella, Listeria, MRSA and Legionella (each an own PRM),
the corresponding dataframes are returned within a list.
}
\description{
RIDOM_comptable_re_evaluate
}
\examples{
Re_Eval <- RIDOM_comptable_re_evaluate(
old_folder =
"O:/Abteilung Humanmedizin (AHM)/Referat 32/32_6/13_QM/Validierung Pipeline/2025_03_19/",
new_folder =
 "O:/Abteilung Humanmedizin (AHM)/Referat 32/32_6/13_QM/Validierung Pipeline/2025_03_20/")

}
\seealso{
\code{\link[=vignette]{vignette("QM_pipeline_evaluation")}}
}
