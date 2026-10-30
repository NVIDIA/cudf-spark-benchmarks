
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(ss.ss_ticket_number) AS total_store_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
),
web_sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_profit,
        COUNT(ws_order_number) AS total_web_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_bill_customer_sk
),
combined_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_store_profit,
        cs.total_store_sales,
        COALESCE(ws.total_web_profit, 0) AS total_web_profit,
        COALESCE(ws.total_web_sales, 0) AS total_web_sales
    FROM 
        customer_sales cs
    LEFT JOIN 
        web_sales_summary ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
),
ranked_sales AS (
    SELECT 
        c.c_customer_sk,
        cs.total_store_profit,
        cs.total_web_profit,
        cs.total_store_sales + cs.total_web_sales AS total_sales_count,
        RANK() OVER (ORDER BY (cs.total_store_profit + cs.total_web_profit) DESC) AS sales_rank
    FROM 
        combined_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    r.sales_rank,
    r.c_customer_sk,
    r.total_store_profit,
    r.total_web_profit,
    r.total_sales_count
FROM 
    ranked_sales r
WHERE 
    r.total_sales_count > 10
ORDER BY 
    r.sales_rank
LIMIT 50;
