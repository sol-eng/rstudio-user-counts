#! /usr/local/bin/Rscript

# Set log file path
log_path <- "/var/lib/rstudio-server/audit/r-sessions/r-sessions.csv"

# Set minimum date - default is 1 year ago
min_date <- as.POSIXct(Sys.Date() - 365)
max_date <- as.POSIXct(Sys.Date() + 1)

# Set CSV path for MAU data write
csv_path <- gsub(" ", "-", paste0("./rsp-user-counts-", Sys.time(), ".csv"))

# Set monthly value
monthly <- TRUE

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
  p <- arg_parser(description = "Active RStudio Server Pro User Counts. This utility should be executed as root.")
  p <- add_argument(parser = p, 
                    arg = "--log-path", 
                    help = "Path to RStudio Session logs",
                    type = "character",
                    default = log_path)
  p <- add_argument(parser = p,
                    arg = "--min-date",
                    help = "Minimum date to compute user counts",
                    type = "character",
                    default = format(min_date, "%Y-%m-%d"))
  p <- add_argument(parser = p,
                    arg = "--max-date",
                    help = "Maximum date to compute user counts",
                    type = "character",
                    default = format(max_date, "%Y-%m-%d"))
  p <- add_argument(parser = p,
                    arg = "--output",
                    help = "Path to write .csv file of user counts",
                    type = "character",
                    default = csv_path)
  p <- add_argument(parser = p,
                    arg = "--monthly",
                    help = "Count active users by month",
                    flag = TRUE)
  p <- add_argument(parser = p,
                    arg = "--debug",
                    help = "Enable debug output",
                    flag = TRUE)
  
  argv <- parse_args(p)
  
  log_path <- argv$log_path
  min_date <- as.POSIXct(argv$min_date)
  csv_path <- argv$output
  monthly <- argv$monthly
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
log_data$month <- format(log_data$timestamp, format = "%Y-%m")

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
if (monthly) {
  print_debug("Counting monthly active users")
  counts <- unique(all_counts[all_counts$active, c("user", "month", "active")])
  counts <- as.data.frame(table(counts$month))
  names(counts) <- c("Month", "Active User Count")
} else {
  counts <- all_counts[all_counts$active, "user"]
  counts <- paste0(length(unique(counts)), " unique RStudio Server Pro named users between ", format(min_date, "%Y-%m-%d"), " and ", format(max_date, "%Y-%m-%d"))
}


# Write CSV
print_debug(paste0("Writing user counts data to ", csv_path))
write.csv(all_counts, csv_path, row.names = FALSE)

# Print final user counts
print(counts, row.names = FALSE)
