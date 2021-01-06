# Monthly Active User Counts

The two scripts here will generate counts of monthly active users for RStudio
Server Pro and RStudio Connect.

### Dependencies
#### System
Each script assumes that R and Rscript are installed and available at
`/usr/local/bin/`. If that's not the case, you need to manually specify the path
to `Rscript` before running the script:
```
/path/to/Rscript ./mau-rsp.R
```

If Rscript is available in `/usr/local/bin/`, then you can simply execute the
files:
```
./mau-rsp.R
```

#### R Packages
One primary focus of these scripts is to introduce minimal R dependencies. Each
script can be run interactively without any dependencies, or, if run as a CLI,
there is only a single dependency:
[argparser](https://cran.r-project.org/web/packages/argparser/index.html). This
package itself introduces no additional external dependencies.

In order to install this package and make it available when running the scripts,
execute the following:
```
sudo /path/to/R -e "install.packages('argparser', repos = 'https://cran.rstudio.com/')"
```

### Usage
Each script can either be run as a CLI or run in an interactive R session.
In order to run the script interactively, start an R session and run through
each line of the script, adjusting the variables as needed.

#### RStudio Server Pro
The `mau-rsp.R` script uses the r-sessions log file to determine session counts.
This log file can be configured following the [instructions in the RStudio
Server Pro administration
guide](https://docs.rstudio.com/ide/server-pro/auditing-and-monitoring.html#r-session-auditing).
The default path for this file is
`/var/lib/rstudio-server/audit/r-sessions/r-sessions.csv`. The script looks for
the file in the default path, but this can be changed with the `--log-path`
parameter. By default, this log file can only be read by the root user,
therefore **it is recommended to run this script with root privileges on the
RStudio Server Pro server.**

```bash
$ ./mau-rsp.R -h
usage: mau-rsp.R [--] [--help] [--debug] [--opts OPTS] [--log-path
       LOG-PATH] [--min-date MIN-DATE] [--output OUTPUT]

Monthly Active RStudio Server Pro User Counts

flags:
  -h, --help      show this help message and exit
  -d, --debug     Enable debug output

optional arguments:
  -x, --opts      RDS file containing argument values
  -l, --log-path  Path to RStudio Session logs [default:
                  /var/lib/rstudio-server/audit/r-sessions/r-sessions.csv]
  -m, --min-date  Minimum date to compute monthly counts [default:
                  2019-12-17 17:00:00]
  -o, --output    Path to write .csv file of user counts [default:
                  ./rsp-user-counts-2020-12-17-10:27:32.csv]
```

#### RStudio Connect
The `mau-rsc.R` script uses the `usermanager` cli to generate the log file
needed to calculate monthly users. In order for the CLI to be used, [RStudio
Connect must be
stopped](https://docs.rstudio.com/connect/admin/server-management/#stopping-starting)
if you use the SQLite database provider.
**It is recommended to run this script with root privileges on the RStudio
Connect server.**

```bash
$ ./mau-rsc.R -h                                                      
usage: mau-rsc.R [--] [--help] [--debug] [--opts OPTS] [--min-date
       MIN-DATE] [--max-date MAX-DATE] [--output OUTPUT]

Monthly Active RStudio Connect User Counts

flags:
  -h, --help      show this help message and exit
  -d, --debug     Enable debug output

optional arguments:
  -x, --opts      RDS file containing argument values
  -m, --min-date  Minimum date to compute monthly counts [default:
                  2019-12-17 17:00:00]
  --max-date      Maximum date to compute monthly counts [default:
                  2020-12-17 17:00:00]
  -o, --output    Path to write .csv file of user counts [default:
                  ./rsc-user-counts-2020-12-17-10:28:08.csv]
```

### Output
Each script will print a table of monthly user counts to `stdout`. It will also
write a csv file containing more specific information about individual user
activity per month.

### Combine
The `mau-combine.R` script can be used to combine the CSV output from
`mau-rsp.R` and `mau-rsc.R`. This can be helpful in order to easily identify
users who are using both RStudio Server Pro and RStudio Connect.

```bash
$ ./mau-combine.R -h
usage: mau-combine.R [--] [--help] [--debug] [--opts OPTS] [--rsp-path
       RSP-PATH] [--rsc-path RSC-PATH] [--output OUTPUT]

Combine Monthly Active User Counts

flags:
  -h, --help      show this help message and exit
  -d, --debug     Enable debug output

optional arguments:
  -x, --opts      RDS file containing argument values
  -r, --rsp-path  Path to output from mau-rsp
  --rsc-path      Path to output from mau-rsc
  -o, --output    Path to write combined .csv file of user counts
                  [default: ./combined-mau-counts-2020-12-17
                  11:09:23.csv]
```

The output of the script is a CSV file containing combined data from the two
input files.

### Anonymize
In the event that you want to anonymize users in the output file, the
`mau-anonymize.R` script can be used to randomly anonymize users by assigning
them a numeric ID.

```bash
$ ./mau-anonymize.R -h
usage: mau-anonymize.R [--] [--help] [--debug] [--opts OPTS]
       [--data-path DATA-PATH] [--output OUTPUT]

Anonymize MAU user counts data

flags:
  -h, --help       show this help message and exit
  --debug          Enable debug output

optional arguments:
  -x, --opts       RDS file containing argument values
  -d, --data-path  Path to MAU counts output file
  -o, --output     Path to write .csv file of anonymized user counts
                   [default: ./anonymized-mau-counts-2020-12-17
                   11:10:44.csv]
```
