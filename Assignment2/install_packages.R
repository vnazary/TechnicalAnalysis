# BDA400 Assignment 2 - Technical Analysis using R, Preliminary Stage
# Installs the R packages used for technical analysis.
# Run once: Rscript install_packages.R  (or Source it in RStudio)

required_packages <- c(
  "quantmod", # downloads stock prices and draws financial charts
  "TTR",      # Technical Trading Rules: moving averages and other indicators
  "xts",      # time series objects that quantmod returns
  "zoo"       # helpers used by xts
)

# Install only the packages that are missing
installed <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed)

if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
} else {
  print("All required packages are already installed.")
}

# Load each package to confirm the installation worked, and print its version
for (package_name in required_packages) {
  library(package_name, character.only = TRUE)
  print(paste(package_name, "version", as.character(packageVersion(package_name))))
}
