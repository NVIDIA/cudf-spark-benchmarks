
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
), 
shop_stats AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ss.total_sales,
    ss.total_revenue,
    ss.avg_order_value
FROM 
    ranked_customers rc
JOIN 
    customer_addresses ca ON rc.c_customer_sk = ca.ca_address_sk
JOIN 
    shop_stats ss ON rc.c_customer_sk = ss.s_store_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_purchase_estimate DESC;
