
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profits,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_bill_customer_sk
),
ProfitableCustomers AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(sd.total_profits, 0) AS total_profits,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_id = cr.c_customer_id
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    pc.c_customer_id,
    pc.total_returns,
    pc.total_profits,
    pc.total_orders,
    CASE 
        WHEN pc.total_returns > 0 AND pc.total_profits = 0 THEN 'High Return, No Profit'
        WHEN pc.total_returns = 0 AND pc.total_profits > 0 THEN 'No Return, Profitable'
        WHEN pc.total_returns > 0 AND pc.total_profits > 0 THEN 'Returns and Profit'
        ELSE 'No Transactions'
    END AS customer_category
FROM 
    ProfitableCustomers pc
WHERE 
    pc.total_orders > 0
ORDER BY 
    pc.total_profits DESC, pc.total_returns ASC;
