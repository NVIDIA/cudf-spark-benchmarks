
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        COALESCE(NULLIF(c.c_email_address, ''), 'No Email') AS email_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
purchase_data AS (
    SELECT 
        CASE 
            WHEN ws.ws_sales_price > 100 THEN 'High Value'
            WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS purchase_category,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        purchase_category
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    pd.total_orders,
    pd.total_profit,
    pd.purchase_category
FROM 
    customer_info ci
LEFT JOIN 
    purchase_data pd ON pd.total_orders > 0
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    ci.full_name;
