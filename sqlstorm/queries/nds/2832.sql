
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2022
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amt
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sd.ws_item_sk = sr.sr_item_sk
    GROUP BY sd.ws_item_sk, sd.total_quantity, sd.total_sales, i.i_item_desc, i.i_current_price
    HAVING sd.total_sales > 1000
),
FinalResults AS (
    SELECT
        ts.ws_item_sk,
        ts.i_item_desc,
        ts.total_sales,
        ts.total_quantity,
        ts.total_returns,
        ts.total_return_amt,
        ROUND((ts.total_sales - ts.total_return_amt), 2) AS net_sales,
        CASE
            WHEN ts.total_sales > 5000 THEN 'High'
            WHEN ts.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM TopSales ts
)
SELECT 
    f.ws_item_sk,
    f.i_item_desc,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.total_return_amt,
    f.net_sales,
    f.sales_category
FROM FinalResults f
WHERE f.total_quantity > (SELECT AVG(total_quantity) FROM FinalResults) 
ORDER BY f.net_sales DESC
LIMIT 10;
