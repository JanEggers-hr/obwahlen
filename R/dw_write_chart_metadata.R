# Aus dem DatawRappr-Paket abgeschriebene, modifizierte Funktion,
# die einen kompletten Metadatensatz hochlädt. 


#' Handle errors in API call
#'
#' Internal function: Handles errors while calling the Datawrapper-API.
#'
#' @param r Required. A httr-response-object.
#' @return A list with the content of the respone-object - or an error,
#' @author Benedict Witzenberger
#' @examples
#'
#' \dontrun{dw_handle_errors(r)}
#'
#' @rdname dw_handle_errors
#' @keywords Internal

dw_handle_errors <- function(r) {
  # error handling
  if (httr::http_type(r) != "application/json" & httr::http_type(r) != "application/octet-stream") {
    stop("API did not return json", call. = FALSE)
  }
  
  if (httr::http_error(r)) {
    stop(
      sprintf(
        "Datawrapper API request failed [%s]\n%s",
        httr::status_code(r),
        httr::content(r, "parsed")$message
      ),
      call. = FALSE
    )
  }
  
  # separate check for type application/json;
  # to avoid raising an error when exporting a chart which returns application/octet-stream
  
  if (httr::http_type(r) == "application/json") {
    parsed <- jsonlite::fromJSON(httr::content(r, "text"), simplifyVector = FALSE)
    
    if (length(parsed[["data"]]) > 1) {
      parsed[["data"]] <- list(parsed[["data"]])
    }
    
    return(parsed)
  }
  
  # end of error handling
  
}

dw_check_chart_id <- function(chart_id) {
  
  if (class(chart_id) == "dw_chart") {
    chart_id <- chart_id[["id"]]
  } else if (class(chart_id) == "character") {
    if (!grepl("[a-zA-Z0-9_]{5}", chart_id)) {
      stop("Entered chart_id is not valid!", call. = FALSE)
    }
  }
  return(chart_id)
}



.DatawRappr_ua <- httr::user_agent(
  sprintf(
    "DatawRappr package v%s: (<%s>)",
    utils::packageVersion("DatawRappr"),
    utils::packageDescription("DatawRappr")$URL
  )
) -> .DATAWRAPPR_UA

dw_call_api <- function(..., return_raw_response=F, enforce_json_response=T) {
  r <- httr::RETRY(...)
  
  httr::handle_reset("https://api.datawrapper.de/")
  
  if (!(httr::status_code(r) %in% c(200, 201, 202, 204))) {
    stop(paste0("There has been an error in an API call. Statuscode of the response: ", httr::status_code(r)), immediate. = TRUE)
  }
  
  if (return_raw_response) {
    return (r)
  }
  
  if (!enforce_json_response) {
    return (httr::content(r))
  }
  
  parsed <- dw_handle_errors(r)
  
  return(parsed)
}



dw_write_chart_metadata <- function(chart_id, api_key = "environment", meta = list(), ...) {
  
  if (api_key == "environment") {
    api_key <- dw_get_api_key()
  }
  
  chart_id <- dw_check_chart_id(chart_id)
  # Check metadata!
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # 
  # Right now, it just expects to find a dw_chart object: 
  # a list of 
  try(if (chart_id != meta[["id"]]) stop("ID != ID"))
  # create empty body for API-call with dw_chart object
  call_body <- list(metadata = list())
  call_body$title <- meta$content$title
  call_body$type <- meta$content$type
  call_body$folderId <- meta$content$folderId
  call_body$intro <- meta$content$intro
  call_body$metadata$annotate <- meta$content$metadata$annotate
  call_body$metadata$describe$byline <- meta$content$metadata$describe$byline
  
  
  
  
  call_body$metadata <- meta$content$metadata
  
  # change only specified parts of existing data

  # send call to API
  # upload modified data
  # solution for API v1:
  # url_upload <- paste0("https://api.datawrapper.de/charts/", chart_id)
  #
  # r <- dw_call_api("PUT", url_upload, httr::add_headers(Authorization = paste("Bearer", api_key, sep = " ")),
  #                       body = call_body, encode = "json", .DATAWRAPPR_UA)
  
  url_upload <- paste0("https://api.datawrapper.de/v3/charts/", chart_id)
  parsed <- dw_call_api("PATCH", url_upload, httr::add_headers(Authorization = paste("Bearer", api_key, sep = " ")),
                        body = call_body, encode = "json", .DATAWRAPPR_UA)
  
  chart_id_response <- parsed["id"][[1]] #for v3: parsed["id"][[1]], for v1: parsed[["data"]][[1]][["id"]]
  
  try(if (chart_id != chart_id_response) stop(paste0("The chart_ids between call (",  chart_id ,") and response (",  chart_id_response ,") do not match. Try again and check API.")))
  
  if (chart_id == chart_id_response) {
    
    message(paste0("Chart ", chart_id_response, " succesfully updated.", "\n"))
    
  } else {
    stop(paste0("There has been an error in the upload process."), immediate. = TRUE)
  }
  
  httr::handle_reset(url_upload)
  
}
