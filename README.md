# TechnicalAnalysis
BDA400 Data Science Tools and Techniques: technical analysis of stocks in R, one folder per assignment

Author: Vahid Nazari

## Assignment 2: Technical Analysis using R, Preliminary Stage

Folder: [`Assignment2`](Assignment2)

| File | Purpose |
|---|---|
| `Nazari_Vahid_CA_BDA400_A02.docx` | The assignment report, with a screenshot of each step |
| `portfolio.txt` | The portfolio: one Toronto Stock Exchange symbol per line (RY.TO, TD.TO, SHOP.TO, ENB.TO, CNQ.TO) |
| `install_packages.R` | Installs and loads quantmod, TTR, xts and zoo |
| `technical_analysis_functions.R` | `load_stock_data()`, `calculate_statistics()`, `calculate_portfolio_statistics()` and the display and chart functions |
| `run_analysis.R` | Main script: loads the portfolio, computes the statistics, prints the tables and saves the charts |
| `portfolio_statistics.csv` | The statistics table produced by `run_analysis.R` |
| `plots/` | Candlestick and moving average charts for each stock, and a portfolio comparison chart |
| `screenshots/` | Screenshots of each setup step used in the report |

### How to run

1. Install R and RStudio.
2. Open `Assignment2/Assignment2.Rproj` in RStudio.
3. Run `source("install_packages.R")` once.
4. Run `source("run_analysis.R")`. It downloads the last 365 days of prices from Yahoo Finance, so it needs an internet connection.
