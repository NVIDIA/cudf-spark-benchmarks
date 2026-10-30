
WITH  CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, hd.hd_income_band_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) as rnk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
, DateRange AS (
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
, SalesSummary AS (
    SELECT ws.ws_sold_date_sk, SUM(ws.ws_sales_price) AS TotalSales,
           COUNT(DISTINCT ws.ws_order_number) AS OrderCount
    FROM web_sales ws
    INNER JOIN DateRange dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_sold_date_sk
)
SELECT ch.c_first_name, ch.c_last_name, ch.hd_income_band_sk, 
       ss.TotalSales, ss.OrderCount,
       DENSE_RANK() OVER (PARTITION BY ch.hd_income_band_sk ORDER BY ss.TotalSales DESC) AS SalesRank,
       (SELECT AVG(TotalSales) FROM SalesSummary) AS AvgTotalSales
FROM CustomerHierarchy ch
LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_sold_date_sk
WHERE ch.rnk = 1 AND NULLIF(ss.TotalSales, 0) IS NOT NULL
ORDER BY ch.hd_income_band_sk, SalesRank;
