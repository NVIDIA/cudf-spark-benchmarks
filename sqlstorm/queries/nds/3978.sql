
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        (c.c_birth_country = 'USA' OR c.c_birth_country IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_profit,
        cs.total_store_profit,
        cs.web_order_count,
        cs.store_order_count,
        RANK() OVER (ORDER BY cs.total_web_profit + cs.total_store_profit DESC) AS sales_rank
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_web_profit,
        r.total_store_profit,
        r.web_order_count,
        r.store_order_count
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
),
sales_date AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_dow,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_date, d.d_month_seq, d.d_year, d.d_dow
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    SUM(sd.total_web_sales) AS total_web_sales,
    SUM(sd.total_store_sales) AS total_store_sales,
    AVG(tc.total_web_profit + tc.total_store_profit) AS avg_profit_per_customer
FROM 
    top_customers tc
JOIN 
    sales_date sd ON sd.d_year = 2023
GROUP BY 
    tc.c_first_name, tc.c_last_name
ORDER BY 
    avg_profit_per_customer DESC;
