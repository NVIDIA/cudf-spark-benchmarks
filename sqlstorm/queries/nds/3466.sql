
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) + COALESCE(SUM(cs.cs_ext_sales_price), 0) + COALESCE(SUM(ss.ss_ext_sales_price), 0) AS grand_total
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), ranked_customers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY grand_total DESC) AS sales_rank
    FROM 
        customer_sales c
)
SELECT 
    rc.c_customer_sk, 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.total_web_sales,
    rc.total_catalog_sales,
    rc.total_store_sales,
    rc.grand_total,
    (SELECT COUNT(*) FROM ranked_customers rc2 WHERE rc2.grand_total > rc.grand_total) AS num_higher_sales
FROM 
    ranked_customers rc
WHERE 
    rc.sales_rank <= 10;
