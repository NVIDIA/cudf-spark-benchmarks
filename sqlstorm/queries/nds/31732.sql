
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    UNION ALL
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        cs_quantity, 
        cs_sales_price,
        cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
AggregatedSales AS (
    SELECT 
        s.ws_item_sk AS item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_ext_sales_price) AS total_sales,
        AVG(s.ws_sales_price) AS avg_price
    FROM web_sales s
    LEFT OUTER JOIN SalesCTE cte ON s.ws_item_sk = cte.ws_item_sk
    GROUP BY s.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    a.item_sk,
    a.total_quantity,
    a.total_sales,
    a.avg_price,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    a.total_sales - COALESCE(cr.total_return_amt, 0) AS net_sales
FROM AggregatedSales a
LEFT JOIN CustomerReturns cr ON a.item_sk = cr.sr_item_sk
WHERE (a.total_quantity > 100 AND a.avg_price > 20) 
   OR (a.total_sales < 5000 AND COALESCE(cr.total_returned, 0) >= 10)
ORDER BY net_sales DESC
LIMIT 50;
