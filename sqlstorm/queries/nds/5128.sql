
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        s.s_store_id
), 
customer_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS transaction_count,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
), 
top_customers AS (
    SELECT 
        cus.c_customer_id,
        cus.transaction_count,
        cus.total_spent,
        RANK() OVER (ORDER BY cus.total_spent DESC) AS rank
    FROM 
        customer_summary cus
)
SELECT 
    sales.s_store_id,
    sales.total_sales,
    sales.total_transactions,
    sales.avg_net_profit,
    tc.c_customer_id,
    tc.transaction_count,
    tc.total_spent
FROM 
    sales_summary sales
LEFT JOIN 
    top_customers tc ON sales.total_sales > 1000 
ORDER BY 
    sales.total_sales DESC, 
    tc.total_spent DESC
LIMIT 10;
