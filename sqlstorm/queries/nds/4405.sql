
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank
    FROM 
        customer_sales c
),
sales_distribution AS (
    SELECT 
        sr.sales_rank,
        COUNT(*) AS customer_count
    FROM 
        sales_rank sr
    GROUP BY 
        sr.sales_rank
)
SELECT 
    CASE 
        WHEN sd.sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN sd.sales_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Other Customers'
    END AS customer_category,
    SUM(sd.customer_count) AS number_of_customers,
    SUM(COALESCE(cs.total_web_sales, 0)) AS total_web_sales,
    SUM(COALESCE(cs.total_catalog_sales, 0)) AS total_catalog_sales,
    SUM(COALESCE(cs.total_store_sales, 0)) AS total_store_sales
FROM
    sales_distribution sd
JOIN 
    sales_rank cs ON sd.sales_rank = cs.sales_rank
GROUP BY 
    customer_category
ORDER BY 
    customer_category;
