#! /usr/local/bin/Rscript

# Set default values
data_path <- NULL
debug <- FALSE
csv_path <- paste0("./anonymized-mau-counts-", Sys.time(), ".csv")


# Print Debug utility
print_debug <- function(msg) {
  if(debug) cat(msg, "\n")
}

# Parse arguments if run as CLI
if (!interactive()) {
  library(argparser, quietly = TRUE)
  p <- arg_parser("Anonymize MAU user counts data")
  p <- add_argument(parser = p, 
                    arg = "--data-path", 
                    help = "Path to MAU counts output file",
                    type = "character",
                    default = data_path)
  p <- add_argument(parser = p,
                    arg = "--output",
                    help = "Path to write .csv file of anonymized user counts",
                    type = "character",
                    default = csv_path)
  p <- add_argument(parser = p,
                    arg = "--debug",
                    help = "Enable debug output",
                    flag = TRUE)
  
  argv <- parse_args(p)
  
  data_path <- argv$data_path
  csv_path <- argv$output
  debug <- argv$debug
}

if (is.null(data_path) | is.na(data_path)) stop("Please provide a valid path for input data")

print_debug(paste0("Reading data: ", data_path))
input_data <- read.csv(data_path, 
                       stringsAsFactors = FALSE,
                       strip.white = TRUE)

print_debug("Anonymizing users")
users <- sample(unique(input_data$user))
user_key <- data.frame(
  user = users,
  random_id = paste0("user", 1:length(users))
)
output_data <- merge(input_data, user_key, by = "user")[,c("month", "random_id", "sessions", "active", "product")]
names(output_data)[2] <- "user"
output_data <- output_data[order(output_data$month, output_data$user),]

print_debug(paste0("Writing data: ", csv_path))
write.csv(output_data, csv_path, row.names = FALSE)
