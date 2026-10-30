WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
WebSalesAggregates AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_sales_profit,
        AVG(ws_net_paid_inc_tax) AS avg_web_sales_per_order
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws_bill_customer_sk
), 
Combined AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_store_returns, 0) AS total_store_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(cr.avg_return_quantity, 0) AS avg_return_quantity,
        COALESCE(ws.total_web_sales_profit, 0) AS total_web_sales_profit,
        COALESCE(ws.avg_web_sales_per_order, 0) AS avg_web_sales_per_order
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
    LEFT JOIN 
        WebSalesAggregates ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    combined.total_store_returns,
    combined.total_return_amount,
    combined.total_return_tax,
    combined.avg_return_quantity,
    combined.total_web_sales_profit,
    combined.avg_web_sales_per_order
FROM 
    customer c
JOIN 
    Combined combined ON c.c_customer_sk = combined.c_customer_sk
WHERE 
    (combined.total_store_returns > 0 OR combined.total_web_sales_profit > 0)
ORDER BY 
    combined.total_return_amount DESC, combined.total_web_sales_profit DESC;