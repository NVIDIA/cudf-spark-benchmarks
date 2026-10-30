
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        sr.sr_returned_date_sk IS NOT NULL 
    GROUP BY 
        c.c_customer_id
), 
SalesData AS (
    SELECT 
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_ship_mode_sk
),
SalesSummary AS (
    SELECT 
        sm.sm_ship_mode_id,
        sd.total_quantity_sold,
        sd.total_sales_value,
        sd.total_orders,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        (sd.total_sales_value - COALESCE(cr.total_return_value, 0)) AS net_sales_after_returns
    FROM 
        SalesData AS sd
    JOIN 
        ship_mode AS sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN 
        CustomerReturns AS cr ON cr.c_customer_id = 'cust1' 
)
SELECT 
    ss.sm_ship_mode_id,
    ss.total_quantity_sold,
    ss.total_sales_value,
    ss.total_orders,
    ss.total_returns,
    ss.total_return_value,
    ss.net_sales_after_returns,
    CASE 
        WHEN ss.net_sales_after_returns > 0 THEN 'Profit'
        ELSE 'Loss or No Sales'
    END AS sales_status
FROM 
    SalesSummary AS ss
ORDER BY 
    ss.net_sales_after_returns DESC
LIMIT 10;
