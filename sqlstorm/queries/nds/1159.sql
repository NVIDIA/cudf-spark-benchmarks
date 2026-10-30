
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_ext_sales_price,
        r.ws_quantity
    FROM 
        RankedSales r
    WHERE 
        r.rank_sales <= 5
),
TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_order_number,
        ts.ws_ext_sales_price,
        ts.ws_quantity,
        COALESCE(tr.total_return_quantity, 0) AS return_quantity,
        COALESCE(tr.total_return_amount, 0) AS return_amount
    FROM 
        TopSales ts
    LEFT JOIN 
        TotalReturns tr ON ts.ws_item_sk = tr.sr_item_sk
)
SELECT 
    sa.ws_item_sk,
    SUM(sa.ws_ext_sales_price) AS total_sales,
    SUM(sa.return_quantity) AS total_returned,
    (SUM(sa.ws_ext_sales_price) - SUM(sa.return_amount)) AS net_sales
FROM 
    SalesAndReturns sa
GROUP BY 
    sa.ws_item_sk
HAVING 
    (SUM(sa.ws_ext_sales_price) - SUM(sa.return_amount)) > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
