
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
), customer_demographics AS (
    SELECT 
        d.cd_demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics d ON cs.c_customer_sk = d.cd_demo_sk
    GROUP BY 
        d.cd_demo_sk, d.cd_gender, d.cd_marital_status, d.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS demographic_group_count,
    SUM(cd.avg_sales) AS total_avg_sales
FROM 
    customer_demographics cd
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_avg_sales DESC
LIMIT 10;
