
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count
    FROM customer c
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL OR cs.cs_sold_date_sk IS NOT NULL
    GROUP BY ws.ws_ship_date_sk
),
IncomeBandCounts AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    WHERE h.hd_buy_potential = 'High'
    GROUP BY h.hd_income_band_sk
)
SELECT 
    cr.c_customer_sk,
    cr.catalog_return_count,
    cr.web_return_count,
    sbc.customer_count AS high_income_customer_count,
    COALESCE(sd.total_web_sales, 0) AS total_web_sales,
    COALESCE(sd.total_catalog_sales, 0) AS total_catalog_sales
FROM CustomerReturns cr
JOIN IncomeBandCounts sbc ON cr.c_customer_sk = sbc.customer_count 
LEFT JOIN SalesData sd ON sd.ws_ship_date_sk = (
    SELECT MAX(ws_ship_date_sk) FROM web_sales
)
WHERE cr.catalog_return_count > 0 OR cr.web_return_count > 0
ORDER BY cr.catalog_return_count DESC, cr.web_return_count DESC;
