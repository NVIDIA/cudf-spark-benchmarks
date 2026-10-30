
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy = 1
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
CombinedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.cs_quantity), 0) AS catalog_sales,
        COALESCE(SUM(ws.ws_quantity), 0) AS web_sales
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesComparison AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.total_sales,
        cs.catalog_sales,
        (ch.total_sales - COALESCE(cs.catalog_sales, 0)) AS sales_difference,
        CASE 
            WHEN ch.total_sales > COALESCE(cs.catalog_sales, 0) THEN 'Web Sales dominate'
            WHEN ch.total_sales < COALESCE(cs.catalog_sales, 0) THEN 'Catalog Sales dominate'
            ELSE 'Equal Sales'
        END AS sales_pattern
    FROM 
        SalesHierarchy ch
    LEFT JOIN 
        CombinedSales cs ON ch.c_customer_sk = cs.c_customer_sk
)
SELECT 
    sc.c_customer_sk,
    sc.c_first_name,
    sc.c_last_name,
    sc.total_sales,
    sc.catalog_sales,
    sc.sales_difference,
    sc.sales_pattern,
    CASE 
        WHEN sc.total_sales IS NULL THEN 'No Sales Recorded' 
        ELSE 'Sales Data Available' 
    END AS sales_record_status
FROM 
    SalesComparison sc
WHERE 
    sc.sales_pattern != 'Equal Sales'
ORDER BY 
    sc.total_sales DESC, sc.sales_difference ASC;
