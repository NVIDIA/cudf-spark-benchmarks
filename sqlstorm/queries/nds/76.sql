
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales + cs.total_web_sales AS total_sales
    FROM 
        customer_sales cs
    WHERE 
        (cs.total_store_sales + cs.total_web_sales) > 10000
),
sales_summary AS (
    SELECT
        COALESCE(hv.total_sales, 0) AS total_sales,
        cw.cd_gender, 
        cw.cd_marital_status,
        cd.customer_count
    FROM 
        high_value_customers hv
    FULL OUTER JOIN 
        customer_demographics cw ON hv.c_customer_sk = cw.cd_demo_sk
    FULL OUTER JOIN 
        customer_demographics cd ON cw.cd_demo_sk = cd.cd_demo_sk
)
SELECT 
    gs.total_sales,
    gs.cd_gender,
    gs.cd_marital_status,
    gs.customer_count,
    ROW_NUMBER() OVER (PARTITION BY gs.cd_marital_status ORDER BY gs.total_sales DESC) AS sales_rank
FROM 
    sales_summary gs
WHERE 
    gs.total_sales IS NOT NULL 
ORDER BY 
    gs.total_sales DESC;
