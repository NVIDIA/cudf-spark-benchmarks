
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS unique_returns
    FROM 
        catalog_returns 
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        ss.total_orders,
        CASE
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'High Risk'
            WHEN COALESCE(ss.total_net_profit, 0) > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_category
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_net_profit,
    tc.total_orders,
    tc.customer_category
FROM 
    TopCustomers tc
WHERE 
    (tc.total_orders > 5 OR tc.total_returns > 0)
ORDER BY 
    tc.total_net_profit DESC,
    tc.total_returns DESC
LIMIT 50;

