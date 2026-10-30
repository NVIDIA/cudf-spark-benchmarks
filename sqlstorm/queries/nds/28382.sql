
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
web_activity AS (
    SELECT 
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_char_count,
        wp.wp_image_count,
        COUNT(*) AS visit_count
    FROM 
        web_page wp
    JOIN 
        web_returns wr ON wp.wp_web_page_sk = wr.wr_web_page_sk
    GROUP BY 
        wp.wp_web_page_id, wp.wp_url, wp.wp_char_count, wp.wp_image_count
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.full_address,
    wa.visit_count,
    ss.total_net_profit,
    ss.total_orders,
    ss.total_quantity
FROM 
    customer_info ci
LEFT JOIN 
    web_activity wa ON ci.c_customer_sk = wa.visit_count 
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M'
ORDER BY 
    ss.total_net_profit DESC
LIMIT 100;
