
WITH customer_info AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd_marital_status,
        cd_gender,
        ca_city,
        ca_state
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
promotions AS (
    SELECT 
        p.p_promo_name,
        p.p_channel_details,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales AS ws
    JOIN 
        promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name, p.p_channel_details
),
final_results AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.ca_city,
        ci.ca_state,
        p.p_promo_name,
        p.total_orders,
        p.total_revenue
    FROM 
        customer_info AS ci
    LEFT JOIN 
        promotions AS p ON ci.ca_city = 'San Francisco' AND p.total_orders > 10
)
SELECT 
    full_name, 
    c_email_address, 
    cd_marital_status, 
    cd_gender, 
    ca_city, 
    ca_state, 
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name, 
    COALESCE(p.total_orders, 0) AS total_orders, 
    COALESCE(p.total_revenue, 0.00) AS total_revenue
FROM 
    final_results AS p
ORDER BY 
    total_revenue DESC, 
    full_name ASC
LIMIT 100;
