
WITH sales_summary AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales_transactions,
        d.d_year
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        s.ss_store_sk, s.ss_item_sk, d.d_year
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
        SUM(s.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_birth_year > 1980 
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ss.ss_store_sk,
    SUM(ss.total_quantity_sold) AS total_quantity_sold,
    SUM(ss.total_net_paid) AS total_net_paid,
    SUM(cs.total_transactions) AS total_transactions,
    SUM(cs.total_spent) AS total_spent
FROM 
    sales_summary ss 
JOIN 
    customer_summary cs ON ss.ss_store_sk = cs.c_customer_sk
GROUP BY 
    ss.ss_store_sk
ORDER BY 
    total_net_paid DESC
LIMIT 10;
