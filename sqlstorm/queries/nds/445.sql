
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
),
DetailedReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_value,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns AS sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    tc.customer_id,
    tc.total_spent,
    tc.order_count,
    dr.total_returns,
    dr.avg_return_value
FROM 
    TopCustomers AS tc
LEFT JOIN 
    DetailedReturns AS dr ON tc.rank <= 10
WHERE 
    dr.total_returns IS NULL OR dr.total_returns > 0
ORDER BY 
    tc.rank;
