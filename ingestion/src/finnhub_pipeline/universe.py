"""Static symbol universe used by the ingestion pipeline."""

SECTOR_UNIVERSE = {
    "Technology": ["AAPL", "MSFT", "NVDA", "GOOGL", "META", "AVGO", "ADBE", "CRM"],
    "Healthcare": ["JNJ", "UNH", "PFE", "ABBV", "MRK"],
    "Financials": ["JPM", "BAC", "GS", "BRK.B", "V"],
    "Consumer Discretionary": ["AMZN", "TSLA", "HD", "NKE", "MCD"],
    "Consumer Staples": ["PG", "KO", "PEP", "WMT"],
    "Industrials": ["CAT", "BA", "HON", "UPS"],
    "Energy": ["XOM", "CVX", "COP", "SLB"],
    "Communication Services": ["DIS", "NFLX", "CMCSA", "T"],
    "Utilities": ["NEE", "DUK", "SO"],
    "Real Estate": ["AMT", "PLD", "CCI", "SPG"],
    "Materials": ["LIN", "APD", "SHW", "ECL"],
}

US_SYMBOLS = [symbol for sector_symbols in SECTOR_UNIVERSE.values() for symbol in sector_symbols]
