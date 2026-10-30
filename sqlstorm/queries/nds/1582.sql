
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_net_loss) AS avg_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        COUNT(cs.cs_order_number) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        promotion p
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_quantity,
        cr.total_return_amount,
        cr.avg_net_loss,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM 
        customer c
    INNER JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_return_quantity > 5
),
TransactionStatistics AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        (SUM(ws.ws_net_paid) / NULLIF(COUNT(ws.ws_order_number), 0)) AS avg_spent_per_order
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_return_quantity,
    tc.total_return_amount,
    tc.avg_net_loss,
    ts.total_spent,
    ts.total_orders,
    ts.avg_spent_per_order,
    p.total_sales,
    p.total_net_profit
FROM 
    TopCustomers tc
LEFT JOIN 
    TransactionStatistics ts ON tc.c_customer_sk = ts.ws_bill_customer_sk
LEFT JOIN 
    Promotions p ON ts.ws_bill_customer_sk = p.p_promo_sk
WHERE 
    ts.total_spent > 100
ORDER BY 
    tc.rank;
