
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COUNT(DISTINCT o.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN (SELECT ws_bill_customer_sk, ws_order_number FROM web_sales GROUP BY ws_bill_customer_sk, ws_order_number) o ON o.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN' 
            ELSE 
                CASE 
                    WHEN cd.cd_purchase_estimate < 1000 THEN 'LOW'
                    WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM'
                    ELSE 'HIGH' 
                END 
        END AS purchase_band
    FROM 
        customer_demographics cd
),
active_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cd.cd_gender,
        cd.purchase_band,
        cs.total_web_sales,
        cs.total_store_sales,
        cs.total_catalog_sales,
        cs.total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_orders DESC) AS rn
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_orders > 0
)
SELECT 
    ac.c_customer_id,
    ac.cd_gender,
    ac.purchase_band,
    ac.total_web_sales,
    ac.total_store_sales,
    ac.total_catalog_sales,
    ac.total_orders
FROM 
    active_customers ac
WHERE 
    ac.rn <= 5
ORDER BY 
    ac.cd_gender, ac.total_orders DESC;
