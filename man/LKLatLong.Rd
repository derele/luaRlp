% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data-docs.R
\docType{data}
\name{LKLatLong}
\alias{LKLatLong}
\title{Landkreise in Rheinland-Pfalz: Centroids of Latitude and Longitude}
\format{
A tibble with 36 rows and 2 variables:
\describe{
  \item{Meldekreis}{Name of the Landkreis (starting LK for Landkreis)}
  \item{Lat/Long of Isolation}{The latitude and Longitude of the Landkreis'
  centroid separated by a comma}
  }
}
\source{
Compiled by Thomas Stelzer and Anja Schoeps
}
\usage{
data(LKLatLong)
}
\description{
Centroids (thier latitude and longitude) of the Landkreise in Rheinland-Pfalz
We might remove this dataset at some point and include code to generate the
centroids from geographic shapes. We should do so when we use the shapes for
other purposes.
}
\examples{
data(LKLatLong)
head(LKLatLong)
}
\keyword{datasets}
