# these functions override internal functions in the {bskyr} package to
# correct for issues in the parsing of URLs

# alternative URL parser
parse_urls <- function(txt) {
  # capture only URL not adjacent space/bracket
  url_regex <- '((https?:\\/\\/[\\S]+)|((?<domain>[a-z][a-z0-9]*(\\.[a-z0-9]+)+)[\\S]*))'

  parse_regex(txt, regex = url_regex)

}

# alternative byte counting
weight_by_bytes <- function(txt) {
  cumsum(nchar(unlist(strsplit(txt, character())), "bytes"))
}

# alternative regex processor
parse_regex <- function(txt, regex, drop_n = 0L) {
    
  matches <- stringr::str_locate_all(txt, regex)
  
  txt_cum_wts <- weight_by_bytes(txt)

  lapply(seq_along(matches), function(m) {
    lapply(seq_len(nrow(matches[[m]])), function(r) {
      list(
        start = txt_cum_wts[matches[[m]][r, 1]]-1,
        end = txt_cum_wts[matches[[m]][r, 2]],
        text = substr(txt, matches[[m]][r, 1], matches[[m]][r, 2])
      )
    })
  })

}

# override functions within the {bskyr} namespace
assignInNamespace("parse_urls", parse_urls, ns = "bskyr")
assignInNamespace("weight_by_bytes", weight_by_bytes, ns = "bskyr")
assignInNamespace("parse_regex", parse_regex, ns = "bskyr")
  
