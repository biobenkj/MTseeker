% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/decomposeAndCalcConsequences.R
\name{decomposeAndCalcConsequences}
\alias{decomposeAndCalcConsequences}
\title{Decompose and annotate AA changes in MT variants}
\usage{
decomposeAndCalcConsequences(mvr, AAchanges = TRUE, parallel = FALSE,
  ...)
}
\arguments{
\item{mvr}{An MVRangesList or MVRanges object}

\item{AAchanges}{Whether to annotate amino acid (AA) changes}

\item{parallel}{Whether to run things in parallel}

\item{...}{Other arguments to pass to injectMTVariants}
}
\value{
Annotated variants
}
\description{
Decompose and annotate AA changes in MT variants
}
\examples{

library(MTseeker)
library(MTseekerData)
library(VariantTools)

#Set a really high depth filter
#This is just for an example and not something you'd use to filter real data
#Something like 10-20 reads is more reasonable
filters <- FilterRules(list(minTotalDepth = MinTotalDepthFilter(min.depth = 2000L)))
ronks_vars.anno <- RONKSvariants[1]
ronks_vars.anno <- MVRangesList(lapply(ronks_vars.anno, subsetByFilter, filters))
ronks_vars.anno <- decomposeAndCalcConsequences(ronks_vars.anno)

}
