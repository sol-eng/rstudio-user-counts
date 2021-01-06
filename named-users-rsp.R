#! /usr/local/bin/Rscript

# Set log file path
log_path <- "/var/lib/rstudio-server/audit/r-sessions/r-sessions.csv"

# Set minimum date - default is 1 year ago
min_date <- as.POSIXct(Sys.Date() - 365)

# Set CSV path for MAU data write
csv_path <- gsub(" ", "-", paste0("./rsp-user-counts-", Sys.time(), ".csv"))

# Set debug value
debug <- FALSE

# Print Debug utility
print_debug <- function(msg) {
  if(debug) cat(msg, "\n")
}

print_dims <- function(dat) {
  dims <- dim(dat)
  print_debug(paste0("\tData dimensions: ", paste0(dims[1], " x ", dims[2])))
}

count_metric <- function(log_data, metric) {
  print_debug(paste0("Calculating ", metric, " counts ----"))
  print_debug(paste0("\tFiltering to ", metric, " events"))
  log_data <- log_data[metric == log_data$type, ]
  
  print_debug("\tSelecting only timestamp, month, and username")
  log_data <- log_data[,c("timestamp", "month", "username")]
  print_dims(log_data)
  
  # Count sessions per user per month
  print_debug(paste0("\tCounting ", metric, " events per user per month"))
  user_metric_counts <- as.data.frame(table(log_data$username, log_data$month))
  names(user_metric_counts) <- c("user", "month", metric)
  user_metric_counts$product <- "RStudio Server Pro"
  print_debug(paste0("Finished calculating ", metric, " counts ----"))
  
  user_metric_counts
}

# Parse arguments if run as CLI
if (!interactive()) {
  library(argparser, quietly = TRUE)
  p <- arg_parser("Monthly Active RStudio Server Pro User Counts")
  p <- add_argument(parser = p, 
                    arg = "--log-path", 
                    help = "Path to RStudio Session logs",
                    type = "character",
                    default = log_path)
  p <- add_argument(parser = p,
                    arg = "--min-date",
                    help = "Minimum date to compute monthly counts",
                    type = "character",
                    default = as.character(min_date))
  p <- add_argument(parser = p,
                    arg = "--output",
                    help = "Path to write .csv file of user counts",
                    type = "character",
                    default = csv_path)
  p <- add_argument(parser = p,
                    arg = "--debug",
                    help = "Enable debug output",
                    flag = TRUE)
  
  argv <- parse_args(p)
  
  log_path <- argv$log_path
  min_date <- as.POSIXct(argv$min_date)
  csv_path <- argv$output
  debug <- argv$debug
}

# Read log data
print_debug(paste0("Reading data: ", log_path))
log_data <- read.csv(log_path, 
                     stringsAsFactors = FALSE, 
                     strip.white = TRUE)
print_dims(log_data)

# Convert timestamp from numeric
print_debug("Converting timestamp")
log_data$timestamp <- as.POSIXct(log_data$timestamp / 1000, origin = "1970-01-01")
print_dims(log_data)

# Filter to events >= min_date
print_debug(paste0("Filtering to events >= ", min_date))
log_data <- log_data[log_data$timestamp >= min_date,]
print_dims(log_data)

# Extract month and year
print_debug("Extracting month from timestamp")
log_data$month <- format(log_data$timestamp, format = "%m-%Y")

# Count session_start events
session_counts <- count_metric(log_data, "session_start")

# Count auth_login events
login_counts <- count_metric(log_data, "auth_login")

# Combine data
print_debug("Combining login and session counts")
all_counts <- merge(session_counts, login_counts, all = TRUE)
names(all_counts) <- c("user", "month", "product", "sessions", "logins")
all_counts$sessions[is.na(all_counts$sessions)] <- 0
all_counts$logins[is.na(all_counts$logins)] <- 0

# Create active column indicating the user logged in OR started a session
print_debug("Identifying active users")
all_counts$active <- all_counts$sessions > 0 | all_counts$logins > 0

# Count monthly active users
print_debug("Counting monthly active users")
mau_counts <- unique(all_counts[all_counts$active, c("user", "month", "active")])
mau_counts <- as.data.frame(table(mau_counts$month))
names(mau_counts) <- c("Month", "Active User Count")

# Write CSV
print_debug(paste0("Writing user counts data to ", csv_path))
write.csv(all_counts, csv_path, row.names = FALSE)

# Print final user counts
print(mau_counts, row.names = FALSE)
