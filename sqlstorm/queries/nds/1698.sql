
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS total_catalog_sales,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
sales_with_demo AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_web_sales DESC) AS rank_within_gender
    FROM 
        sales_with_demo
    WHERE 
        total_web_sales IS NOT NULL
)
SELECT 
    rs.c_customer_sk,
    rs.total_web_sales,
    rs.total_catalog_sales,
    rs.total_store_sales,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_education_status,
    rs.cd_purchase_estimate,
    rs.rank_within_gender
FROM 
    ranked_sales rs
WHERE 
    rs.rank_within_gender <= 10
ORDER BY 
    rs.cd_gender, rs.rank_within_gender;
