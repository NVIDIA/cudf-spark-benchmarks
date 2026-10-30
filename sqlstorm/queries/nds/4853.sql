
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_value,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        COALESCE(ws.total_sales_value, 0) AS total_sales_value,
        COALESCE(ws.total_orders, 0) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS customer_full_name,
    tc.total_returns,
    tc.total_return_value,
    tc.total_sales_value,
    tc.total_orders,
    ROUND((tc.total_sales_value - tc.total_return_value), 2) AS net_sales_value,
    CASE 
        WHEN tc.total_sales_value > 0 THEN ROUND((tc.total_returns * 100.0 / tc.total_orders), 2)
        ELSE NULL 
    END AS return_rate_percentage
FROM 
    TopCustomers tc
WHERE 
    tc.total_orders > 10
ORDER BY 
    net_sales_value DESC
LIMIT 10;
