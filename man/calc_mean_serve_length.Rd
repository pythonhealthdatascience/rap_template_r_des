% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_run_results.R
\name{calc_mean_serve_length}
\alias{calc_mean_serve_length}
\title{Calculate the mean length of time patients spent with each resource}
\usage{
calc_mean_serve_length(arrivals, resources, groups = NULL)
}
\arguments{
\item{arrivals}{Dataframe with times for each patient with each resource.}

\item{resources}{Dataframe with times patients use or queue for resources.}

\item{groups}{Optional list of columns to group by for the calculation.}
}
\value{
Tibble with columns containing result for each resource.
}
\description{
Calculate the mean length of time patients spent with each resource
}
