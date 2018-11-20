# devtools::load_all()

hca <- HumanCellAtlas(per_page=100)

## possibly on a page that has no data?
res <- hca %>%
    filter(library_construction_approach == "EFO:0008931" &
        paired_end == True & ncbi_taxon_id == 9606 & process_type == "analysis") %>%
    results() %>%
    as_tibble()

res

source("inst/scripts/fqids_site.R")

bundle_fqids <- head(bundle_fqids_markus)
# bundle_fqids <- res %>% pull('bundle_fqid') %>% unique() %>% head(2)

matrix_query_url <- "https://matrix.data.humancellatlas.org/v0/matrix"
GET(matrix_query_url)
## Content-Type: application/json


library(httr)

body <- list(bundle_fqids = bundle_fqids, format = "loom")
header <- .build_header(FALSE)
response <- httr::POST(matrix_query_url, header, body = body, encode = "json", httr::verbose())
req_id <- httr::content(response)$request_id

req_address <- file.path(matrix_query_url, req_id)
get_response <- httr::GET(req_address)
# content(get_response)

while (identical(httr::content(httr::GET(req_address))$status, "In Progress"))
    Sys.sleep(20)

get_response <- httr::GET(req_address)
mat_url <- httr::content(get_response)$matrix_location

library(LoomExperiment)

downloader::download(mat_url, "loomfile.loom")
lex <- LoomExperiment::import("loomfile.loom")

colnames(lex) <- colData(lex)[["CellID"]]
