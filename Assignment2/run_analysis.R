# BDA400 Assignment 2 - Technical Analysis using R, Preliminary Stage
# Main script: loads the portfolio, computes the statistics and displays the results.
# Open this folder in RStudio (Session > Set Working Directory > To Source File Location)
# and click Source, or run: Rscript run_analysis.R

source("technical_analysis_functions.R")

# 1. Load one year of daily prices for every symbol in portfolio.txt
portfolio_symbols <- read_portfolio("portfolio.txt")
print(portfolio_symbols)

stock_data <- load_stock_data("portfolio.txt", from = Sys.Date() - 365, to = Sys.Date())

# One data frame per symbol, for example stock_data[["RY.TO"]]
print(names(stock_data))
str(stock_data[[1]])

# 2. Compute the statistics for every stock
portfolio_statistics <- calculate_portfolio_statistics(stock_data, short_window = 20, long_window = 50)

# 3. Display the data and the statistics
display_quote_summary(stock_data)
display_stock_data(stock_data, rows = 5)
display_statistics(portfolio_statistics$summary_table)

# Save the statistics so they can be opened in Excel
write.csv(portfolio_statistics$summary_table, "portfolio_statistics.csv", row.names = FALSE)

# 4. Visualize the data and the statistics
plot_stock_charts(portfolio_statistics$by_symbol, output_dir = "plots")
plot_portfolio_comparison(stock_data, output_dir = "plots")
print("Charts saved in the plots folder.")
