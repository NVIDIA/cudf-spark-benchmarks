
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_value,
        wss.total_orders,
        wss.total_sales,
        wss.avg_net_profit
    FROM 
        CustomerReturns cr
    JOIN 
        WebSalesSummary wss ON cr.sr_customer_sk = wss.ws_bill_customer_sk
    WHERE 
        cr.total_returns > 5 AND wss.total_orders > 10
)
SELECT 
    COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS customer_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS total_return_value,
    COALESCE(ws.total_orders, 0) AS total_orders,
    COALESCE(ws.total_sales, 0) AS total_sales,
    COALESCE(ws.avg_net_profit, 0) AS avg_net_profit,
    ROW_NUMBER() OVER (ORDER BY cr.total_return_value DESC) AS ranking
FROM 
    HighReturnCustomers cr
LEFT JOIN 
    customer c ON cr.sr_customer_sk = c.c_customer_sk
LEFT JOIN 
    WebSalesSummary ws ON cr.sr_customer_sk = ws.ws_bill_customer_sk
WHERE 
    cr.total_return_value IS NOT NULL
ORDER BY 
    total_return_value DESC;
