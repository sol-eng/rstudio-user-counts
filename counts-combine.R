#! /usr/local/bin/Rscript

# Set default paths
rsp_mau_path <- NULL
rsc_mau_path <- NULL

# Output path
csv_path <- paste0("./combined-mau-counts-", Sys.time(), ".csv")

# Print Debug utility
print_debug <- function(msg) {
  if(debug) cat(msg, "\n")
}

# Set debug value
debug <- FALSE

# Parse arguments if run as CLI
if (!interactive()) {
  library(argparser, quietly = TRUE)
  p <- arg_parser("Combine Monthly Active User Counts")
  p <- add_argument(parser = p, 
                    arg = "--rsp-path", 
                    help = "Path to output from mau-rsp",
                    type = "character",
                    default = rsp_mau_path)
  p <- add_argument(parser = p,
                    arg = "--rsc-path",
                    help = "Path to output from mau-rsc",
                    type = "character",
                    default = rsc_mau_path)
  p <- add_argument(parser = p,
                    arg = "--output",
                    help = "Path to write combined .csv file of user counts",
                    type = "character",
                    default = csv_path)
  p <- add_argument(parser = p,
                    arg = "--debug",
                    help = "Enable debug output",
                    flag = TRUE)
  
  argv <- parse_args(p)
  
  rsp_mau_path <- argv$rsp_path
  rsc_mau_path <- argv$rsc_path
  csv_path <- argv$output
  debug <- argv$debug
}

if (is.null(rsp_mau_path) | is.na(rsp_mau_path) | is.null(rsc_mau_path) | is.na(rsc_mau_path)) {
  stop("Please provide a valid path for the output from both mau-rsp.R and mau-rsc.R")
}

print_debug(paste0("Reading ", rsp_mau_path))
rsp_counts <- read.csv(rsp_mau_path, 
                       stringsAsFactors = FALSE,
                       strip.white = TRUE)

print_debug(paste0("Reading ", rsc_mau_path))
rsc_counts <- read.csv(rsc_mau_path, 
                       stringsAsFactors = FALSE,
                       strip.white = TRUE)

print_debug("Combining user counts")
selected_columns <- c("month", "user", "product", "active")
combined_counts <- rbind(rsp_counts[,selected_columns], 
                         rsc_counts[,selected_columns])
combined_counts <- combined_counts[order(combined_counts$month, combined_counts$user),]

print_debug(paste0("Writing combined counts to ", csv_path))
write.csv(combined_counts, csv_path, row.names = FALSE)
