
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.customer_sk,
        cs.total_orders,
        cs.total_profit,
        cs.avg_order_value,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt
    FROM 
        SalesSummary cs
    LEFT JOIN 
        CustomerReturns cr ON cs.customer_sk = cr.sr_customer_sk
    WHERE 
        cs.total_orders > 5 
        AND cs.total_profit > 1000
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hvc.total_orders,
    hvc.total_profit,
    hvc.avg_order_value,
    hvc.total_returned_quantity,
    hvc.total_returned_amt,
    CASE 
        WHEN hvc.total_returned_quantity > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_returns
FROM 
    customer c
JOIN 
    HighValueCustomers hvc ON c.c_customer_sk = hvc.customer_sk
ORDER BY 
    hvc.total_profit DESC,
    hvc.total_orders DESC
LIMIT 100;
