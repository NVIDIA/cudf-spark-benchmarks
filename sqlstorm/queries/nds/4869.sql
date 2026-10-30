
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(cd.cd_credit_rating, 'NA') AS credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count, cd.cd_credit_rating
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM 
        customer_data
    WHERE 
        total_orders > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.dependent_count,
    tc.credit_rating,
    COALESCE(CAST(wp.wp_creation_date_sk AS STRING), 'No Page Access') AS web_page_access,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
    sm.sm_carrier,
    sm.sm_code
FROM 
    top_customers tc
LEFT JOIN 
    web_page wp ON tc.c_customer_sk = wp.wp_customer_sk
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    tc.order_rank <= 10 
    AND (tc.dependent_count > 0 OR tc.credit_rating = 'Good')
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.cd_marital_status, tc.dependent_count, tc.credit_rating, wp.wp_creation_date_sk, sm.sm_carrier, sm.sm_code
ORDER BY 
    total_spent DESC;
