# BDA400 Assignment 2 - Technical Analysis using R, Preliminary Stage
# Utility functions to load stock data, compute basic statistics and display the results.
# Use with: source("technical_analysis_functions.R")

library(quantmod)
library(TTR)

# ---------------------------------------------------------------------------
# Loading data
# ---------------------------------------------------------------------------

# Reads the stock symbols from a text file, one symbol per line.
# Blank lines and lines starting with # are ignored.
read_portfolio <- function(portfolio_file = "portfolio.txt") {
  lines <- trimws(readLines(portfolio_file, warn = FALSE))
  symbols <- lines[lines != "" & !startsWith(lines, "#")]
  toupper(symbols)
}

# Reads portfolio.txt and downloads the daily prices of every symbol from Yahoo Finance
# with quantmod. Returns a named list with one data frame per symbol, with the columns
# Date, Open, High, Low, Close, Volume and Adjusted.
load_stock_data <- function(portfolio_file = "portfolio.txt",
                            from = Sys.Date() - 365,
                            to = Sys.Date()) {
  symbols <- read_portfolio(portfolio_file)
  stock_data <- list()

  for (symbol in symbols) {
    prices <- tryCatch(
      getSymbols(symbol, src = "yahoo", from = from, to = to, auto.assign = FALSE),
      error = function(e) {
        warning(paste("Could not download", symbol, ":", conditionMessage(e)))
        NULL
      }
    )
    if (is.null(prices)) {
      next
    }

    # Turn the xts object into a plain data frame with a Date column
    stock_frame <- data.frame(Date = index(prices), coredata(prices))
    colnames(stock_frame) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adjusted")
    stock_frame <- stock_frame[!is.na(stock_frame$Close), ]
    stock_data[[symbol]] <- stock_frame
  }

  stock_data
}

# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------

# Base R has no function for the statistical mode, so this returns the most frequent value.
# Prices are rounded to whole dollars first, because exact prices rarely repeat.
calculate_mode <- function(values, digits = 0) {
  rounded <- round(values[!is.na(values)], digits)
  counts <- table(rounded)
  as.numeric(names(counts)[which.max(counts)])
}

# Calculates the moving averages, mean, mode, median and standard deviation of one stock's
# closing price. Returns a list with a one-row summary data frame and the stock data with
# the moving average columns added.
calculate_statistics <- function(stock_frame, short_window = 20, long_window = 50) {
  close_prices <- stock_frame$Close

  # Simple moving averages from the TTR package
  stock_frame$SMA_short <- SMA(close_prices, n = short_window)
  stock_frame$SMA_long <- SMA(close_prices, n = long_window)

  # Daily return in percent
  stock_frame$Daily_Return <- c(NA, diff(close_prices) / head(close_prices, -1) * 100)

  summary_row <- data.frame(
    Days = nrow(stock_frame),
    First_Date = min(stock_frame$Date),
    Last_Date = max(stock_frame$Date),
    Last_Close = tail(close_prices, 1),
    Mean = mean(close_prices, na.rm = TRUE),
    Median = median(close_prices, na.rm = TRUE),
    Mode = calculate_mode(close_prices),
    Std_Dev = sd(close_prices, na.rm = TRUE),
    Min = min(close_prices, na.rm = TRUE),
    Max = max(close_prices, na.rm = TRUE),
    SMA_short = tail(stock_frame$SMA_short, 1),
    SMA_long = tail(stock_frame$SMA_long, 1),
    Mean_Volume = mean(stock_frame$Volume, na.rm = TRUE)
  )
  names(summary_row)[names(summary_row) == "SMA_short"] <- paste0("SMA_", short_window)
  names(summary_row)[names(summary_row) == "SMA_long"] <- paste0("SMA_", long_window)

  list(summary = summary_row, data = stock_frame)
}

# Runs calculate_statistics() on every stock in the list. Returns a list with one entry per
# symbol and a combined summary table with one row per symbol.
calculate_portfolio_statistics <- function(stock_data, short_window = 20, long_window = 50) {
  results <- lapply(stock_data, calculate_statistics,
                    short_window = short_window, long_window = long_window)
  summary_table <- do.call(rbind, lapply(names(results), function(symbol) {
    cbind(Symbol = symbol, results[[symbol]]$summary)
  }))
  rownames(summary_table) <- NULL

  list(by_symbol = results, summary_table = summary_table)
}

# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

# Prints the first and last rows of each stock's data frame, like a quote table.
display_stock_data <- function(stock_data, rows = 5) {
  for (symbol in names(stock_data)) {
    stock_frame <- stock_data[[symbol]]
    cat("\n==========", symbol, "==========\n")
    cat("Rows:", nrow(stock_frame), " From:", format(min(stock_frame$Date)),
        " To:", format(max(stock_frame$Date)), "\n")
    cat("\nFirst", rows, "trading days:\n")
    print(head(stock_frame, rows), row.names = FALSE, digits = 6)
    cat("\nLast", rows, "trading days:\n")
    print(tail(stock_frame, rows), row.names = FALSE, digits = 6)
  }
}

# Prints a one-line quote per stock: last close, change from the previous day and volume,
# similar to the quote header on Yahoo Finance.
display_quote_summary <- function(stock_data) {
  quotes <- do.call(rbind, lapply(names(stock_data), function(symbol) {
    stock_frame <- stock_data[[symbol]]
    last_row <- tail(stock_frame, 1)
    previous_close <- stock_frame$Close[nrow(stock_frame) - 1]
    change <- last_row$Close - previous_close
    data.frame(
      Symbol = symbol,
      Date = last_row$Date,
      Close = round(last_row$Close, 2),
      Change = round(change, 2),
      Change_Pct = round(change / previous_close * 100, 2),
      Day_Range = paste(round(last_row$Low, 2), "-", round(last_row$High, 2)),
      Volume = format(last_row$Volume, big.mark = ",")
    )
  }))
  cat("\n========== Latest quotes ==========\n")
  print(quotes, row.names = FALSE)
  invisible(quotes)
}

# Prints the statistics table with the numbers rounded to 2 decimals.
display_statistics <- function(summary_table) {
  rounded_table <- summary_table
  numeric_columns <- sapply(rounded_table, is.numeric)
  rounded_table[numeric_columns] <- lapply(rounded_table[numeric_columns], round, 2)
  cat("\n========== Closing price statistics ==========\n")
  print(rounded_table, row.names = FALSE)
  invisible(rounded_table)
}

# Saves one chart per stock: a candlestick chart with volume and moving averages
# (quantmod's chartSeries), and a line chart of the close with its moving averages.
plot_stock_charts <- function(stock_statistics, output_dir = "plots",
                              short_window = 20, long_window = 50) {
  dir.create(output_dir, showWarnings = FALSE)

  for (symbol in names(stock_statistics)) {
    stock_frame <- stock_statistics[[symbol]]$data
    prices <- xts(stock_frame[, c("Open", "High", "Low", "Close", "Volume")],
                  order.by = stock_frame$Date)
    file_symbol <- gsub("[^A-Za-z0-9]", "_", symbol)

    # Candlestick chart with volume and two moving averages
    png(file.path(output_dir, paste0(file_symbol, "_candlestick.png")), width = 1200, height = 700)
    chart_indicators <- paste0("addVo();addSMA(n = ", short_window, ", col = 'blue');",
                               "addSMA(n = ", long_window, ", col = 'red')")
    chartSeries(prices, name = symbol, theme = chartTheme("white"), TA = chart_indicators)
    dev.off()

    # Close price with moving averages, mean and one standard deviation band
    summary_row <- stock_statistics[[symbol]]$summary
    png(file.path(output_dir, paste0(file_symbol, "_close_sma.png")), width = 1200, height = 600)
    plot(stock_frame$Date, stock_frame$Close, type = "l", lwd = 2, col = "black",
         main = paste(symbol, "closing price with moving averages"),
         xlab = "Date", ylab = "Price (CAD)")
    lines(stock_frame$Date, stock_frame$SMA_short, col = "blue", lwd = 2)
    lines(stock_frame$Date, stock_frame$SMA_long, col = "red", lwd = 2)
    abline(h = summary_row$Mean, col = "darkgreen", lty = 2)
    abline(h = summary_row$Mean + c(-1, 1) * summary_row$Std_Dev, col = "gray50", lty = 3)
    legend("topleft", bty = "n",
           legend = c("Close", paste0("SMA ", short_window), paste0("SMA ", long_window),
                      "Mean", "Mean +/- 1 SD"),
           col = c("black", "blue", "red", "darkgreen", "gray50"),
           lty = c(1, 1, 1, 2, 3), lwd = c(2, 2, 2, 1, 1))
    dev.off()
  }
}

# Saves a chart comparing the stocks: each closing price rebased to 100 on the first day.
plot_portfolio_comparison <- function(stock_data, output_dir = "plots") {
  dir.create(output_dir, showWarnings = FALSE)
  rebased <- lapply(stock_data, function(stock_frame) {
    data.frame(Date = stock_frame$Date, Value = stock_frame$Close / stock_frame$Close[1] * 100)
  })
  all_values <- unlist(lapply(rebased, function(frame) frame$Value))
  colours <- rainbow(length(rebased))

  png(file.path(output_dir, "portfolio_comparison.png"), width = 1200, height = 600)
  plot(rebased[[1]]$Date, rebased[[1]]$Value, type = "n", ylim = range(all_values),
       main = "Portfolio performance (closing price rebased to 100)",
       xlab = "Date", ylab = "Value (start = 100)")
  for (i in seq_along(rebased)) {
    lines(rebased[[i]]$Date, rebased[[i]]$Value, col = colours[i], lwd = 2)
  }
  abline(h = 100, lty = 2, col = "gray50")
  legend("topleft", legend = names(rebased), col = colours, lwd = 2, bty = "n")
  dev.off()
}
