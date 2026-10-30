
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales
    FROM customer c
    JOIN RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE rs.sales_rank <= 10
),
SalesByCity AS (
    SELECT 
        ca_city,
        SUM(total_sales) AS city_sales
    FROM HighSpenders hs
    JOIN customer_address ca ON hs.c_customer_sk = ca.ca_address_sk
    GROUP BY ca_city
),
TopCities AS (
    SELECT 
        ca_city,
        city_sales,
        RANK() OVER (ORDER BY city_sales DESC) AS city_rank
    FROM SalesByCity
)
SELECT 
    tc.ca_city,
    tc.city_sales,
    ds.d_year,
    ds.d_month_seq,
    ds.d_day_name
FROM TopCities tc
JOIN date_dim ds ON ds.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk IN (SELECT c_customer_sk FROM HighSpenders))
WHERE tc.city_rank <= 5
ORDER BY tc.city_sales DESC;
