
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_ranks AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_returns,
        RANK() OVER (ORDER BY (cs.total_store_sales + cs.total_web_sales - cs.total_store_returns) DESC) AS sales_rank
    FROM customer_sales cs
),
high_value_customers AS (
    SELECT 
        hvc.*,
        CASE 
            WHEN hvc.total_store_sales + hvc.total_web_sales > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM sales_ranks hvc
    WHERE hvc.sales_rank <= 100
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_store_sales,
    hvc.total_web_sales,
    hvc.total_catalog_sales,
    hvc.total_store_returns,
    hvc.sales_rank,
    hvc.customer_type
FROM high_value_customers hvc
ORDER BY hvc.sales_rank;
