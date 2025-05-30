
#' createEpidata
#'
#' @param LIMS_link_file The file (exported from our LIMS) associating our
#' LUA Probennummern (3263-) and SurvNet IDs (Aktenzeichen with licence plate
#' prefix)
#'
#' @param out The output file in csv format (defaults to  SurvNetExport4RIDOM
#' plus the current timestamp wirtten into
#' "O:/Abteilung Humanmedizin (AHM)/Referat 32/32_6/14_EpiDaten/")
#'
#' @param problems If problematic entries should be reported into a file
#' (a filename or path to a file) should be given. Which entries are regarded as
#' problematic are defined via type_of_problem
#'
#' @param type_of_problem should be "non-matching-LIMS". The currently only
#' available option (also the current default) is to write non-matching LIMS
#' entries to a file (given in the argument "problems").
#'
#' @return Writes a csv file compatible with the RIDOM database scheme "LUA RLP
#' default bacteria to "\strong{out}" and a optionally a second csv file to
#' "\strong{problem}". See "Format".
#'
#'
#' @format  The csv file written to "out" has the following columns:
#' \describe{
#'   \item{Sample ID}{Character. As "Labornummer" from LIMS}
#'   \item{Alias ID (s)}{Character. This is the \strong{merge key}! As
#'   "SurvNet.AZ" from SurvNet and as "Aktenzeichen" from LIMS.}
#'   \item{Zip of Isolation}{Character. As PLZ from LIMS}
#'   \item{IdRecord}{Character. Unchanged from SurvNet}
#'   \item{Collection Date}{Date. As Meldedatum from SurvNet}
#'   \item{Gesundheitsamt}{Character. Via merge based on
#'   Eigentuemer from SurvNet (merge key) obtaining the Gesundheitsamt
#'   variable from data("Eigentuemer")}
#'   \item{Meldelandkreis}{Character. Unchanged from SurvNet}
#'   \item{MunicipalityKey}{Character. Unchanged from SurvNet}
#'   \item{Host Age (years)}{Numeric. As AgeComputed from SurvNet}
#'   \item{Host Sex}{Character. Recoded from Geschlecht from SurvNet}
#'   \item{HospStatus}{Character. Recoded from HospitalisierungStatus from
#'   SurvNet}
#'   \item{VerstorbenStatus}{Character. Recoded from VerstorbenStatus from
#'   SurvNet}
#'   \item{Expositionsort}{Character. Derived from multiple exposure variables
#'   from SurvNet (see ?luaRlp:::.combine_exposure)}
#'   \item{Outbreak}{Logical. Recoded from SurvNet by determining
#'   whether AusbruchInfo_InterneRef is filled}
#'   \item{Country of Isolation}{Character. Hard-coded "Germany".}
#'   \item{Lat/Long of Isolation}{Character. The latitude and longitude of the
#'   centroid of the Landkreis derived from data("LKLatLong") merged via
#'   "Meldelandkreis" (merge key)}
#'   \item{Project}{Character. The RIDOM project name recoded from
#'   Meldekategorie (Erreger) from SurvNet}
#'   \item{Host}{Character. Hardcoded "homo sapiens" for all but Legionella,
#'   which needs to be entered manually (set to "NACHTRAGEN!")}
#'   \item{Source type}{Character. Hardcoded "clinical/host-associated" for all
#'   but Legionella, which needs to be entered manually (set to "NACHTRAGEN!")}
#'   \item{Source subtype}{Character. Hardcoded "human" for all but Legionella,
#'   which needs to be entered manually (set to "NACHTRAGEN!")}
#'   \item{Specimen type}{Character. Hardcoded "stool" for salmonella and EHEC,
#'   "NACHTRAGEN!" for Legionella, MRSA and Listeria}
#'   }
#'
#' @export
#'
#' @importFrom readr write_csv
#' @importFrom magrittr %>%
#' @importFrom utils read.delim
#'
create_Epidata <- function(LIMS_link_file,
         out =
           paste0("O:/Abteilung Humanmedizin (AHM)/Referat 32/32_6/14_EpiDaten/LIMS Import/",
                  "SurvNetExport4RIDOM",
                  format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv"),
         problems = NULL,
         type_of_problem = "non-matching-LIMS"
         ){
  SN <- import_SurvNet() %>%
    .combine_exposure() %>%
    .append_LK_LatLong() %>%
    .append_GA_Kuerzel() %>%
    .cleanup_RIDOM()
  IDs <- read.delim(LIMS_link_file, sep = ";")
  Out_EpiDaten <- inner_join(IDs, SN,
                             by = c("SurvNet.AZ" = "Aktenzeichen")) %>%
    ## rename variables coming from the LIMS merger!
    rename(`Sample ID` = .data$Labornummer,
           `Alias ID (s)` =.data$SurvNet.AZ,
           `Zip of Isolation` = .data$PLZ)
  writeLines(c("\ufeff"), out)
  readr::write_csv(Out_EpiDaten, out)
  ### optinal reporting of a problems-file
  if(!is.null(problems)){
    if(type_of_problem %in%(c("non-matching-LIMS"))){
      p <- IDs %>%
        filter(!SurvNet.AZ %in% SN$Aktenzeichen)
      readr::write_excel_csv2(p, problems)
    }else{
      stop("Choose a type of problem to report when requesting problems output")
    }
  }
  return(Out_EpiDaten)
}

#' import_SurvNet
#'
#' @return A data frame specified columns (hardcoded for now)
#'
#' @export
#'
#' @import odbc
#' @examples
#' import_SurvNet()
#'
#'
import_SurvNet <- function(){
  dsn <- odbcListDataSources()$name
  if (length(dsn) != 1) {
    if (length(dsn) > 1) {
      stop(paste("Multiple potential SurvNet data sources detected.",
                 "Please select one of:", paste(dsn, collapse = ", ")))
    } else {
      stop("No data source detected. Please configure ODBC.")
    }
  }
  # Connect if exactly one DSN is found
  myconn <- dbConnect(odbc(), dsn = dsn)
  # Try running the query and ensure the connection is closed
  data <- tryCatch({
    dbGetQuery(myconn,
               "SELECT DISTINCT [Data].[Version].[Token] AS 'Aktenzeichen' , [Data].[Version].[IdType] AS 'Datensatzkategorie', (SELECT I.ItemName FROM Meta.Catalogue2Item AS C2I INNER JOIN Meta.Item AS I ON C2I.IdItem = I.IdItem WHERE C2I.IdCatalogue = 1010 AND I.IdIndex = [Data].[Disease71].[ReportingCounty]) AS 'Meldelandkreis' ,[Data].[Disease71].[IdVersion], [Data].[Version].[IdType], [Data].[Version].[CodeRecordOwner] AS 'Eigentuemer', [Data].[Version].[IdRecord] AS 'IdRecord', [Data].[Disease71].[Sex] 'Geschlecht' , [Data].[Disease71].[ReportingDate] AS 'Meldedatum' , [Data].[Disease71].[MunicipalityKey] , [Data].[Disease71].[AgeComputed] , [Data].[Disease71].[StatusHospitalization] AS 'HospitalisierungStatus' , [Data].[Disease71].[StatusDeceased] AS 'VerstorbenStatus' ,ExPOI2.ExpKont1, ExPOI2.ExpSubKont1, ExPOI2.ExpLand1, ExPOI2.ExpBL1, ExPOI2.ExpLK1, ExPOI2.ExpKont2, ExOutInfo.AusbruchInfo_InterneRef FROM [Data].[Version] INNER JOIN [Data].[Disease71] ON [Data].[Version].[IdVersion] = [Data].[Disease71].[IdVersion] LEFT OUTER JOIN [Meta].[DayTable] DT1001 ON DT1001.IdDaySQL = CAST(CAST([Data].[Disease71].[ReportingDate] AS FLOAT) AS INT) LEFT OUTER JOIN [Meta].[DayTable] DT1110 ON DT1110.IdDaySQL = CAST(CAST([Data].[Disease71].[OnsetOfDisease] AS FLOAT) AS INT) Outer Apply Data.ExpandWithPlaceOfInfections2(Data.Version.IdVersion) ExPOI2 Outer Apply Data.ExpandWithOutbreakInfo ([Data].[Version].[IdVersion]) ExOutInfo WHERE (GETDATE() BETWEEN [Data].[Version].[ValidFrom] AND [Data].[Version].[ValidUntil]) AND ([Data].[Version].[IsActive] = 1) AND ([Data].[Version].[IdRecordType] = 1) AND (([Data].[Version].[IdType] IN (121,157,179,140,138))) AND (((DT1001.WeekYear>=2023)))")
  },
  error = function(e) {
    message("Error: Failed to execute the SQL query. Check your syntax and connection.")
    message("Details: ", e$message)
    return(NULL)  # Return NULL if an error occurs
  },
  finally = {
    dbDisconnect(myconn)
  })
  return(data)
}


#' .combine_exposure
#'
#' Derives a single "Expositionsort" Variable from multiple exposure-related
#' variables avialiable in SurvNet (via luaRlp::import_SurvNet())
#'
#' @param data Usually a tibble generated by \code{\link{import_SurvNet()}}
#'
#' @return A tibble derived the
#' tibble as generated by \code{\link{import_SurvNet()}}, but with
#' Expositionsort standardized
#'
#'@import dplyr
#'@importFrom magrittr %>%
#'
.combine_exposure <- function(data){
  # function starting with ".", only used internally
  # Expositionsort: Combine information from multiple exposure variables into one
  dplyr::mutate(data,
    Expositionsort = case_when(
      !is.na(.data$ExpKont2) ~ "mehrere Orte",
      !is.na(.data$ExpLK1) & .data$ExpBL1 == "Rheinland-Pfalz" ~
        as.character(.data$ExpLK1),
      !is.na(.data$ExpBL1) & .data$ExpLand1 == "Deutschland" ~
        as.character(ExpBL1),
      !is.na(.data$ExpLand1) ~ as.character(.data$ExpLand1),
      !is.na(.data$ExpSubKont1) ~ as.character(.data$ExpSubKont1),
      !is.na(.data$ExpKont1) ~ as.character(.data$ExpKont1),
      TRUE ~ NA_character_
    )
  ) %>%
  dplyr::select(!starts_with("ExpKont"))  # Remove columns from ExpKont1 to ExpKont2
}


#' .append_LK_LatLong
#'
#' Internal function (not exported), adds the latitude and longitude of the
#' centroid of each Landkreis, see \code{\link{LKLatLong}}
#'
#' @param data Usually a tibble generated by \code{\link{import_SurvNet()}}
#'
#' @return a tibble as generated by \code{\link{import_SurvNet()}}, but with
#' centroids (latitude and longitude) of the Landkreis included
#'
#'@import dplyr
#'
.append_LK_LatLong <- function(data){
  left_join(data, luaRlp::LKLatLong, by = "Meldelandkreis")
}

#' .append_GA_Kuerzel
#'
#' Internal function (not exported) to add the ID (Kuerzel) of the
#' Gesundheitsamt of a particular Landkries (LK)
#'
#' @param data Usually a tibble generated by \code{\link{import_SurvNet()}}
#'
#' @return a tibble as generated by \code{\link{import_SurvNet()}}, but with
#' Meldelandkreis and their IDs included
#'
#' @import dplyr
#' @importFrom magrittr %>%
#'
.append_GA_Kuerzel <- function(data){
# Import codes (Kürzel) for Aktenzeichen and join
  inner_join(data, luaRlp::Eigentuemer, by = "Eigentuemer") %>%
    rename(AZ = .data$Aktenzeichen) %>%
    mutate(Aktenzeichen = gsub(" ", "", paste0(.data$Kürzel, .data$AZ)))
}



#' .cleanup_RIDOM
#'
#' Internal function (not exported), which cleans and prepares SurvNet data
#' for import into RIDOM according to the database scheme defined there.
#'
#' @param data Usually a tibble generated by \code{\link{import_SurvNet()}} and
#' data for Gesundheitsaemter and Landkreise appended
#'
#' @return a tibble
#'
#' @import dplyr
#' @importFrom magrittr %>%
#'
.cleanup_RIDOM <- function(data){
# Final dataset with cleaned and formatted variables
  data %>%
    mutate(
      Meldedatum = as.Date(.data$Meldedatum),
      Outbreak = ifelse(!is.na(.data$AusbruchInfo_InterneRef), 1, 0),
      HospStatus = recode(.data$HospitalisierungStatus,
                          "10" = "no", "20" = "yes", "-1" = "unknown",
                          "0" = "not assessed"),
      VerstorbenStatus = recode(.data$VerstorbenStatus,
                        "10" = "no", "20" = "yes", "-1" = "unknown",
                        "0" = "not assessed"),
      `Host Sex` = recode(.data$Geschlecht,
                          "1" = "male", "2" = "female", "3" = "non-binary",
                          "-1" = "unknown", "0" = "unknown"),
      `Datensatzkategorie` = recode(.data$Datensatzkategorie,
                                    "121" = "EHEC", "138" = "Legionellose",
                                    "140" = "Listeriose", "157" =
                                      "Salmonellose",
                                    "179" = "MRSA"),
      `Project` = recode(.data$Datensatzkategorie,
                         "EHEC" = "Produktiv_EHEC",
                         "Legionellose" = "Produktiv_Legionella_pneumophila",
                         "Listeriose" = "Produktiv_Listeria_monocytogenes",
                         "Salmonellose" = "Produktiv_Salmonella_enterica",
                         "MRSA" = "Produktiv_MRSA"),
      `Country of Isolation` = "Germany"
    ) %>%
    mutate(## everywhere but Legionella human host as default
      `Host` = ifelse(Datensatzkategorie != "Legionellose", "Homo sapiens",
                      "NACHTRAGEN!"),
      `Source type` = ifelse(Datensatzkategorie != "Legionellose",
                           "clinical/host-associated",
                           "NACHTRAGEN!"),
      `Source subtype` = ifelse(Datensatzkategorie != "Legionellose", "human",
                                "NACHTRAGEN!"),
      `Specimen type` = ifelse(Datensatzkategorie %in% c("Salmonellose", "EHEC"),
                               "stool",
                               "NACHTRAGEN!")
        ) %>%
    rename(`Collection Date` = .data$Meldedatum,
           `Host Age (years)` = .data$AgeComputed
    ) %>%
    select(
      .data$Aktenzeichen,
      .data$IdRecord,
      .data$`Collection Date`, .data$Gesundheitsamt, .data$Meldelandkreis,
      .data$MunicipalityKey, .data$`Host Age (years)`, .data$`Host Sex`,
      .data$HospStatus, .data$VerstorbenStatus, .data$Expositionsort,
      .data$Outbreak, .data$`Country of Isolation`,
      .data$`Lat/Long of Isolation`, .data$Project, .data$Host,
      .data$`Source type`, .data$`Source subtype`, .data$`Specimen type`
    )
}

