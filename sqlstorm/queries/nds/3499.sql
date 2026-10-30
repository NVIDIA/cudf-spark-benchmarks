
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        AVG(sr_return_ship_cost) AS avg_ship_cost
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnDetails AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(cr.avg_ship_cost, 0) AS avg_ship_cost,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.avg_sales_price, 0) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.total_returns,
    r.total_return_amount,
    r.total_return_tax,
    r.avg_ship_cost,
    r.total_profit,
    r.total_orders,
    r.avg_sales_price,
    CASE 
        WHEN r.total_returns > 0 THEN 'RETURNING'
        ELSE 'NEW'
    END AS customer_type
FROM 
    ReturnDetails r
WHERE 
    r.total_profit > (SELECT AVG(total_profit) FROM ReturnDetails)
ORDER BY 
    r.total_profit DESC
LIMIT 50;
