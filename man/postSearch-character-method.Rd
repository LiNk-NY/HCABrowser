% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hca-api.R
\docType{methods}
\name{postSearch,character-method}
\alias{postSearch,character-method}
\title{Find bundles by searching their metadata with an Elasticsearch query}
\usage{
\S4method{postSearch}{character}(replica = c("aws", "gcp", "azure"),
  output_format = c("summary", "raw"), es_query, per_page = 100,
  search_after = NULL,
  url = "https://dss.integration.data.humancellatlas.org/v1")
}
\description{
Find bundles by searching their metadata with an Elasticsearch query
}
