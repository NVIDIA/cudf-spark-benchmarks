
WITH CustomerStores AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        customer c
    JOIN 
        store s ON c.c_current_addr_sk = s.s_store_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk AND s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, s.s_store_sk, s.s_store_name
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(cs.cs_quantity) AS total_catalog_sales_quantity 
    FROM 
        store s
    JOIN 
        catalog_sales cs ON s.s_store_sk = cs.cs_ship_mode_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.s_store_sk,
        cs.s_store_name,
        cs.total_sales_quantity,
        ts.total_catalog_sales_quantity
    FROM 
        CustomerStores cs
    LEFT JOIN 
        TopStores ts ON cs.s_store_sk = ts.s_store_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    s.s_store_name, 
    total_sales_quantity, 
    total_catalog_sales_quantity,
    CASE 
        WHEN total_sales_quantity > total_catalog_sales_quantity THEN 'Store Sales Higher'
        WHEN total_sales_quantity < total_catalog_sales_quantity THEN 'Catalog Sales Higher'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    SalesComparison c
JOIN 
    store s ON c.s_store_sk = s.s_store_sk
WHERE 
    s.s_city = 'Seattle'
ORDER BY 
    total_sales_quantity DESC, total_catalog_sales_quantity DESC
LIMIT 10;
