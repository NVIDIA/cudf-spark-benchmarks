
WITH SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
HighValueSales AS (
    SELECT 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        SalesData
    WHERE 
        rn = 1
    GROUP BY 
        ws_order_number
),
ReturnedItems AS (
    SELECT 
        wr_order_number,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_order_number
)
SELECT 
    hs.ws_order_number,
    hs.total_sales,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_return_amount, 0) AS total_return_amount,
    (hs.total_sales - COALESCE(ri.total_return_amount, 0)) AS net_sales
FROM 
    HighValueSales hs
LEFT JOIN 
    ReturnedItems ri ON hs.ws_order_number = ri.wr_order_number
ORDER BY 
    net_sales DESC
LIMIT 100;
