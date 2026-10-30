
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        cs_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS web_sales,
        SUM(cs_ext_sales_price) AS catalog_sales,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COUNT(DISTINCT cs_order_number) AS catalog_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT 
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    COALESCE(ca.web_sales, 0) AS total_web_sales,
    COALESCE(ca.catalog_sales, 0) AS total_catalog_sales,
    (COALESCE(ca.web_sales, 0) + COALESCE(ca.catalog_sales, 0)) AS overall_sales,
    CASE 
        WHEN (COALESCE(ca.web_sales, 0) + COALESCE(ca.catalog_sales, 0)) = 0 THEN 'No sales'
        WHEN (COALESCE(ca.web_sales, 0) > COALESCE(ca.catalog_sales, 0)) THEN 'Web Sales Dominant'
        ELSE 'Catalog Sales Dominant'
    END AS sales_dominance
FROM 
    customer_analysis ca
LEFT JOIN customer_demographics cd ON ca.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY 
    overall_sales DESC
LIMIT 50;
