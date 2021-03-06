.filters_list <- list(
    organ = 'files.specimen_from_organism_json.organ.text',
    organ_part = 'files.specimen_from_organism_son.organ_part.text',
    genus_species = c('files.cell_line_json.genus_species.text',
                      'files.cell_suspension_json.genus_species.text', 
                      'files.donor_organism_json.genus_species.text', 
                      'files.organoid_json.genus_species.text', 
                      'files.specimen_from_organism_json.genus_species.text'),
    organism_age = 'files.donor_organism_json.organism_age.txt',
    instrument_manufacturer_model = 'files.protocol_json.protocols.content.instrument_manufacturer_model.text',
    storage_method = 1,
    library_construction_approach = 'files.protocol_json.protocols.content.library_construction_approach.text',
    organism_age_unit = 'files.biomaterial_json.biomaterials',
    biological_sex = 'files.biomaterial_json.biomaterials',
    disease = 'files.specimen_from_organism.diseases.text',
    versions = 'manifest.version',
    laboratory = 'files.project_json.projects.content.contact.laboratory',
    protocol = 1,
    file_format = c('files.analysis_file_json.file_core.file_format',
                    'files.image_file_json.file_core.file_format',
                    'files.reference_file_json.file_core.file_format',
                    'files.sequence_file_json.file_core.file_format',
                    'files.supplementary_file_json.file_core.file_format'),
    input_aggregate_cell_count = 1
)
.filters <- as.character(.filters_list)
names(.filters) <- names(.filters_list)

.range_ops = list(
    '<' = "lt",
    '<=' = "lte",
    '>' = 'gt',
    '>=' = 'gte'
)

.match_ops = list(
    '==' = '='
)

.parse_EsQuery <- function(es_query)
{
    if (is.null(es_query))
        return(list(query=NULL))
    
}

.supportedFilters <- function()
{
    names(.filters)
}

#' @export
setMethod("supportedFilters", "missing", .supportedFilters)

.binary_op <- function(sep)
{
    force(sep)
    function(e1, e2) {
        browser()
        field <- as.character(substitute(e1))
        field
    }
}

.not_op <- function(sep)
{
    force(sep)
    function(e1, e2) {
        field <- as.character(substitute(e1))
    }
}

.parenthesis_op <- function(sep)
{
    force(sep)
    function(e1, e2) {
        field <- as.character(substitute(e1))
    }
}

.combine_op <- function(sep)
{
    force(sep)
    function(e1, e2) {
        field <- as.character(substitute(e1))
    }
}

.hca_filter_loop <- function(hca, expr)
{
    browser()
    expr <- lazyeval::lazy_(expr, env = environment())
    res <- lazyeval::lazy_eval(expr, data = .LOG_OP_REG)
    res
}

#' @importFrom dplyr filter
#' @importFrom rlang quo lang_head lang_tail
#' @export
.new.filter.HumanCellAtlas <- function(hca, ...)
{
    .dots <- quos(...)
    .dots <- lapply(.dots, rlang::quo_get_expr)
    re <- Reduce(.hca_filter_loop, .dots, init = hca)
    re
}

filter.HumanCellAtlas <- function(hca, ...)
{
    .dots <- quo(...)
    
    q_head <- as.character(lang_head(.dots))
    q_tail_1 <- as.character(lang_tail(.dots)[[1]])
    q_tail_2 <- as.character(lang_tail(.dots)[[2]])

    range <- NULL
    if(q_head %in% names(.range_ops))
        range <- .range_ops[[q_head]]

    filter <- hca@es_query@query@bool@filter
    must_not <- hca@es_query@query@bool@must_not

#    q_tail_1 <- .filters[[q_tail_1]]

    if(is.null(range)) {
        entries <- filter@entries
        term <- .Term(field=q_tail_1, operator=q_head, value=q_tail_2)
#        a <- list(q_tail_2)
#        names(a) <- q_tail_1
#        a <- list(match = a)
        entries <- c(entries, term)
        hca@es_query@query@bool@filter@entries <- entries
    }
    else {
        entries <- filter@entries
        range <- .Range(field=q_tail_1, operator=q_head, value=q_tail_2)
#        a <- list(q_tail_2)
#        names(a) <- range
#        a <- list(a)
#        names(a) <- q_tail_1
        entries <- c(entries, range)
        #hca@es_query$query$bool$must$range <-
        hca@es_query@query@bool@filter@entries <- entries
    }

    hca <- select(hca, q_tail_1)

    hca

    #hca
}

#' @importFrom dplyr select
#' @export
select.HumanCellAtlas <- function(hca, sources)
{
    #sources <- list(...)

    sources <- as.character(sources)

    hca@es_query@es_source@entries <- c(hca@es_query@es_source@entries, sources)
    #query[['_source']] <- c(query[['_source']], list(...))
    #query
    #hca
    postSearch(hca, 'aws', 'raw', per_page=10)
}

.convert_names_to_filters <- function(sources)
{
    sources <- vapply(sources, function(x) {
        if (x %in% names(.filters))
            .filters[x]
        else
            x
    }, character(1))
    names(sources) <- NULL
    sources
}

.convert_filter_to_names <- function(sources)
{
    sources <- vapply(sources, function(x) {
        if (length(aa <- .filters[.filters %in% x]) > 0) {
            names(aa)
        }
        else
            x
    }, character(1))
    names(sources) <- NULL
    sources
}

.build_es_query <- function()
{
    
}

.LOG_OP_REG <- list()
## Assign conditions.
.LOG_OP_REG$`==` <- .binary_op("==")
.LOG_OP_REG$`%in%` <- .binary_op("==")
.LOG_OP_REG$`!=` <- .binary_op("!=")
.LOG_OP_REG$`>` <- .binary_op(">")
.LOG_OP_REG$`<` <- .binary_op("<")
.LOG_OP_REG$`>=` <- .binary_op(">=")
.LOG_OP_REG$`<=` <- .binary_op("<=")
## Custom binary operators 
.LOG_OP_REG$`%startsWith%` <- .binary_op("startsWith")
.LOG_OP_REG$`%endsWith%` <- .binary_op("endsWith")
.LOG_OP_REG$`%contains%` <- .binary_op("contains")
## not conditional.
.LOG_OP_REG$`!` <- .not_op("!")
## parenthesis
.LOG_OP_REG$`(` <- .parenthesis_op("(")
## combine filters
.LOG_OP_REG$`&` <- .combine_op("&")
.LOG_OP_REG$`|` <- .combine_op("|")

`%startsWith%` <- function(e1, e2){}
`%endsWith%` <- function(e1, e2){}
`%contains%` <- function(e1, e2){}

