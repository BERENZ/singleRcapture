% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{carcassubmission}
\alias{carcassubmission}
\title{Carcass submissions}
\format{
Data frame with 1858 rows and 4 columns.
\describe{
\item{TOTAL_SUB}{Number of submissions}
\item{log_size}{logarithm of size of farm}
\item{log_distance}{logarith of distance to nearest AHVLA center}
\item{C_TYPE}{Type of farm 1 for dairy and 0 for beef}
}
}
\usage{
data("carcassubmission")
}
\description{
Carcass submissions
}
\details{
Data on british animal farms submissions to AHVLA. British farms
are able to submit samples to AHVLA if cause of death of an animal
cannot be determined and private veterinary surgeon decides to submit them,
unless there is notifiable disease suspected then it is not required.
This is data on such farms and their submissions. This
data set contains submission of animal carcasses only.
}
\references{
Bohning et.al (2013) BIOMETRICS 69, 1033-1042
}
\keyword{datasets}
