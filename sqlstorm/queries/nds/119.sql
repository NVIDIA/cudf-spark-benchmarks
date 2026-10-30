
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(web.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales web ON c.c_customer_sk = web.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics_sales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_store_sales) AS total_store_sales_by_gender,
        SUM(cs.total_web_sales) AS total_web_sales_by_gender,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_gender
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ranked_demographics AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_web_sales_by_gender DESC) AS web_sales_rank,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_store_sales_by_gender DESC) AS store_sales_rank
    FROM 
        demographics_sales
)
SELECT 
    dd.cd_gender,
    dd.cd_marital_status,
    dd.total_web_sales_by_gender,
    dd.total_store_sales_by_gender,
    dd.web_sales_rank,
    dd.store_sales_rank
FROM 
    ranked_demographics dd
WHERE 
    dd.total_web_sales_by_gender > 0
    AND dd.web_sales_rank <= 5
    OR (dd.store_sales_rank <= 5 AND dd.cd_marital_status = 'M')
ORDER BY 
    dd.cd_gender, dd.total_web_sales_by_gender DESC;
