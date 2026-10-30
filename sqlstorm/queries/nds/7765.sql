
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.total_web_sales,
        c.total_catalog_sales,
        c.total_store_sales,
        RANK() OVER (ORDER BY (c.total_web_sales + c.total_catalog_sales + c.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales AS c
)
SELECT 
    t.customer_id, 
    t.total_web_sales, 
    t.total_catalog_sales, 
    t.total_store_sales
FROM 
    TopCustomers AS t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_web_sales DESC;
