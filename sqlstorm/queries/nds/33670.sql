
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458986 AND 2458988
    GROUP BY ws_item_sk
    UNION ALL
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2458986 AND 2458988
    GROUP BY cs_item_sk
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesWithReturns AS (
    SELECT
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_value, 0) AS total_return_value,
        s.sales_rank
    FROM SalesCTE s
    LEFT JOIN CustomerReturns r ON s.ws_item_sk = r.sr_item_sk
)
SELECT
    w.w_warehouse_name,
    CASE 
        WHEN sw.total_quantity = 0 THEN 'No Sales' 
        ELSE 'Sales Found' 
    END AS sales_status,
    sw.total_quantity,
    sw.total_sales,
    sw.total_returns,
    sw.total_return_value
FROM SalesWithReturns sw
JOIN inventory inv ON sw.ws_item_sk = inv.inv_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE sw.sales_rank = 1
AND inv.inv_quantity_on_hand < 500
ORDER BY sw.total_sales DESC;
