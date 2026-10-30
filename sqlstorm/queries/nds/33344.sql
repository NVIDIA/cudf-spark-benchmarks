
WITH  Sales_CTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity + COALESCE(NULLIF(ws_quantity, 0), 1)) AS total_quantity,
        SUM(ws_ext_sales_price + COALESCE(NULLIF(ws_ext_sales_price, 0), 1)) AS total_sales
    FROM
        web_sales
    WHERE
        ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
Aggregated_Sales AS (
    SELECT
        s.ws_item_sk,
        SUM(s.total_sales) AS grand_total_sales,
        SUM(s.total_quantity) AS grand_total_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY SUM(s.total_sales) DESC) AS sales_rank
    FROM
        Sales_CTE s
    GROUP BY
        s.ws_item_sk
),
Max_Sales AS (
    SELECT
        MAX(grand_total_sales) AS max_sales,
        MAX(grand_total_quantity) AS max_quantity
    FROM
        Aggregated_Sales
)
SELECT
    a.ws_item_sk,
    a.grand_total_sales,
    a.grand_total_quantity,
    MA.max_sales,
    MA.max_quantity,
    CASE
        WHEN a.grand_total_sales = MA.max_sales THEN 'Top Performer'
        ELSE 'Regular'
    END AS performance_category
FROM
    Aggregated_Sales a
CROSS JOIN
    Max_Sales MA
WHERE
    a.grand_total_quantity > (SELECT AVG(AS2.grand_total_quantity) FROM Aggregated_Sales AS2)
ORDER BY
    a.grand_total_sales DESC;
