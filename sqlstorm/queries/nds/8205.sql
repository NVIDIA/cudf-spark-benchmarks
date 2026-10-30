
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) - 30
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_net_paid,
        ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rank
    FROM 
        SalesData
    WHERE 
        total_quantity > 100
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
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
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_paid,
    COALESCE(cr.total_returns, 0) AS total_returns,
    ti.total_net_paid - COALESCE(cr.total_returns, 0) AS net_sales_after_returns
FROM 
    TopItems ti
LEFT JOIN 
    CustomerReturns cr ON ti.ws_item_sk = cr.wr_item_sk
WHERE 
    ti.rank <= 10
ORDER BY 
    net_sales_after_returns DESC;
