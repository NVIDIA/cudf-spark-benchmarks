
WITH  SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY d_year) AS year_rank
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
    HAVING d_year >= 2015
),
YearOverYearGrowth AS (
    SELECT 
        current.d_year,
        current.total_profit,
        COALESCE((current.total_profit - previous.total_profit) / NULLIF(previous.total_profit, 0), 0) AS growth_rate
    FROM SalesGrowth current
    LEFT JOIN SalesGrowth previous ON current.year_rank = previous.year_rank + 1
),
IncomeBandStats AS (
    SELECT 
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON hd.hd_demo_sk = ws.ws_bill_cdemo_sk 
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    y.d_year,
    y.total_profit,
    y.growth_rate,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ib.customer_count,
    ib.total_profit AS band_profit,
    CASE 
        WHEN ib.total_profit IS NOT NULL THEN (y.total_profit - ib.total_profit) / NULLIF(ib.total_profit, 0) 
        ELSE NULL 
    END AS profit_margin_variance
FROM YearOverYearGrowth y
LEFT JOIN IncomeBandStats ib ON y.d_year BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
ORDER BY y.d_year;
