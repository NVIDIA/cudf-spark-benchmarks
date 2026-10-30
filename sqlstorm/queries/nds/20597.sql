
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
purchase_summary AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
), 
discounted_sales AS (
    SELECT 
        cs.cs_ship_customer_sk,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(cs.cs_order_number) AS discount_count
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 0
    GROUP BY cs.cs_ship_customer_sk
)

SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    p.total_quantity,
    p.total_spent,
    p.order_count,
    ds.total_discount,
    COALESCE(ds.discount_count, 0) AS discount_count,
    CASE 
        WHEN rc.gender_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_class
FROM ranked_customers rc
LEFT JOIN purchase_summary p ON rc.c_customer_sk = p.ws_ship_customer_sk
LEFT JOIN discounted_sales ds ON rc.c_customer_sk = ds.cs_ship_customer_sk
WHERE 
    (p.total_spent > 1000 OR (ds.total_discount IS NOT NULL AND ds.total_discount > 50))
    AND rc.cd_marital_status IS NOT NULL
ORDER BY p.total_spent DESC, rc.c_last_name, rc.c_first_name;
