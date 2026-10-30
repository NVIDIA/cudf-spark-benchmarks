
WITH CTE_CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, 
        wr_returning_customer_sk
),

CTE_SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_sold_qty,
        SUM(ws_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim) 
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, 
        ws_ship_date_sk, 
        ws_ship_mode_sk
)

SELECT 
    d.d_date AS sale_date,
    s.sm_type AS shipping_mode,
    COALESCE(sd.total_sold_qty, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales_amt, 0) AS total_sales_amount,
    COALESCE(cr.return_count, 0) AS total_return_count,
    COALESCE(cr.total_return_qty, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    (COALESCE(sd.total_sales_amt, 0) - COALESCE(cr.total_return_amt, 0)) AS net_sales
FROM 
    date_dim d
LEFT JOIN 
    CTE_SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
LEFT JOIN 
    CTE_CustomerReturns cr ON d.d_date_sk = cr.wr_returned_date_sk
LEFT JOIN 
    ship_mode s ON sd.ws_ship_mode_sk = s.sm_ship_mode_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date, s.sm_type;
