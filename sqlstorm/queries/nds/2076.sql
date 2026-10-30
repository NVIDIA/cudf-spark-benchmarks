
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3)
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 3
    GROUP BY 
        rs.ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    (COALESCE(ts.total_sales, 0) - COALESCE(cr.total_return_amt, 0)) AS net_profit
FROM 
    customer c
LEFT JOIN 
    TopSales ts ON c.c_customer_sk = ts.ws_order_number
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    c.c_birth_year < 1980
ORDER BY 
    net_profit DESC
LIMIT 10;
