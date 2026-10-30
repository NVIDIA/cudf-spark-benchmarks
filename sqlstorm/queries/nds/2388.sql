
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY total_sales DESC) AS sales_rank,
        total_quantity,
        total_sales
    FROM 
        SalesData
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_value
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS total_return_value,
    (COALESCE(ts.total_sales, 0) - COALESCE(cr.total_return_value, 0)) AS net_sales
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk AND ts.sales_rank = 1
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    net_sales DESC
LIMIT 100;
