
WITH  Sales_CTE AS (
    SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_ext_sales_price)
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs_item_sk
),
Aggregated_Sales AS (
    SELECT sales.ws_item_sk AS item_key, COALESCE(wp.wp_url, 'N/A') AS web_page,
           SUM(sales.total_sales) AS total_sales_amount
    FROM Sales_CTE sales
    LEFT JOIN web_page wp ON sales.ws_item_sk = wp.wp_web_page_sk
    GROUP BY sales.ws_item_sk, wp.wp_url
),
High_Performance_Sales AS (
    SELECT item_key, web_page, total_sales_amount,
           ROW_NUMBER() OVER (ORDER BY total_sales_amount DESC) AS rank
    FROM Aggregated_Sales
    WHERE total_sales_amount > 10000
)
SELECT h.item_key, h.web_page, h.total_sales_amount, 
       CASE
           WHEN h.total_sales_amount IS NULL THEN 'No Sales' 
           ELSE 'Sales Recorded' 
       END AS sales_status,
       COALESCE(d.d_year, 2022) AS year_of_sales
FROM High_Performance_Sales h
FULL OUTER JOIN date_dim d ON h.rank = d.d_month_seq
WHERE d.d_year IS NOT NULL OR h.item_key IS NOT NULL
ORDER BY h.total_sales_amount DESC, h.web_page ASC;
