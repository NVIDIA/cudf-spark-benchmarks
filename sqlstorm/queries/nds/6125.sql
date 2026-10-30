
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
joined_data AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_marital_status,
        ci.cd_gender,
        si.total_sales,
        si.total_net_profit,
        ci.ca_city,
        ci.ca_state
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data si ON ci.c_customer_sk = si.ws_ship_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT jd.c_customer_sk) AS customer_count,
    AVG(jd.total_sales) AS avg_sales_per_customer,
    SUM(jd.total_net_profit) AS total_profit
FROM 
    joined_data jd
JOIN 
    customer_address ca ON jd.ca_city = ca.ca_city AND jd.ca_state = ca.ca_state
GROUP BY 
    ca.ca_city,
    ca.ca_state
ORDER BY 
    total_profit DESC
LIMIT 10;
