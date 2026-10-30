
WITH  Sales_CTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
    UNION ALL
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        -SUM(sr.sr_return_quantity) AS total_quantity,
        -SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
),
Aggregated_Sales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.total_quantity) AS net_quantity,
        SUM(s.total_sales) AS net_sales
    FROM Sales_CTE s
    GROUP BY s.ws_item_sk
),
Item_Details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(a.net_quantity, 0) AS total_sold_quantity,
        COALESCE(a.net_sales, 0) AS total_sold_value,
        CASE 
            WHEN COALESCE(a.net_sales, 0) > 1000 THEN 'High Performer'
            WHEN COALESCE(a.net_sales, 0) BETWEEN 500 AND 1000 THEN 'Average Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM item i
    LEFT JOIN Aggregated_Sales a ON i.i_item_sk = a.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.total_sold_quantity,
    id.total_sold_value,
    id.performance_category,
    ROW_NUMBER() OVER (PARTITION BY id.performance_category ORDER BY id.total_sold_value DESC) AS rank_within_category
FROM Item_Details id
WHERE id.total_sold_quantity IS NOT NULL
ORDER BY id.performance_category, total_sold_value DESC
LIMIT 10 OFFSET 20;
