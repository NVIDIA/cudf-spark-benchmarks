
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), Promotions AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales_amt,
        COUNT(ws_order_number) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), TopCustomers AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(cr.total_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(p.total_sales_amt), 0) AS total_sales_amt,
        (COALESCE(SUM(cr.total_return_amt), 0) / NULLIF(SUM(p.total_sales_amt), 0)) AS return_ratio
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        Promotions p ON c.c_customer_sk = p.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id
    HAVING 
        (COALESCE(SUM(cr.total_return_amt), 0) / NULLIF(SUM(p.total_sales_amt), 0)) > 0.1
)
SELECT 
    tc.c_customer_id,
    tc.total_return_amt,
    tc.total_sales_amt,
    tc.return_ratio,
    ROW_NUMBER() OVER (ORDER BY tc.return_ratio DESC) AS rank
FROM 
    TopCustomers tc
WHERE 
    tc.return_ratio IS NOT NULL
ORDER BY 
    tc.return_ratio DESC
LIMIT 10;
