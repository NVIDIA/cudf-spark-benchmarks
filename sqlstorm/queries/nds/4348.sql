
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
), sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
), customer_returns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        sr.sr_customer_sk
), return_analysis AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_returned, 0) AS total_returned,
        tc.total_spent
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_returns cr ON tc.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    ra.c_customer_sk,
    ra.c_first_name,
    ra.c_last_name,
    ra.total_spent,
    ra.return_count,
    ra.total_returned,
    ROUND(COALESCE(ra.total_returned / NULLIF(ra.total_spent, 0) * 100, 0), 2) AS return_rate
FROM 
    return_analysis ra
WHERE 
    ra.total_spent > 1000
ORDER BY 
    return_rate DESC
LIMIT 5;
