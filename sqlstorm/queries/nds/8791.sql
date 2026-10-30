
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), top_customers AS (
    SELECT 
        customer_sales.*,
        RANK() OVER (ORDER BY total_spent DESC) AS sales_rank
    FROM 
        customer_sales
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    s.s_store_name,
    COUNT(sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_returned
FROM 
    top_customers t
JOIN 
    store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN 
    store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
WHERE 
    t.sales_rank <= 10
GROUP BY 
    t.c_first_name, t.c_last_name, t.total_spent, s.s_store_name
ORDER BY 
    t.total_spent DESC;
