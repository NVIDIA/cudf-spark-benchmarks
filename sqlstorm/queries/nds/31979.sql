
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_sales_price) DESC) AS sales_rank
    FROM (
        SELECT 
            ws_item_sk,
            ws_quantity,
            ws_sales_price AS ws_net_sales_price
        FROM web_sales
        WHERE ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
        UNION ALL
        SELECT 
            cs_item_sk,
            cs_quantity,
            cs_sales_price AS cs_net_sales_price
        FROM catalog_sales
        WHERE cs_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    ) AS combined_sales
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
TopSales AS (
    SELECT 
        cte.ws_item_sk,
        cte.total_quantity,
        cte.total_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount
    FROM SalesCTE cte
    LEFT JOIN CustomerReturns cr ON cte.ws_item_sk = cr.sr_item_sk
    WHERE cte.sales_rank <= 10
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales_price,
    t.total_returns,
    t.total_returned_amount,
    CASE 
        WHEN t.total_sales_price > 0 THEN 
            ROUND((t.total_returns::decimal / t.total_sales_price) * 100, 2) 
        ELSE 0 
    END AS return_percentage
FROM TopSales t
ORDER BY t.total_sales_price DESC;
