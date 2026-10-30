
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON (c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy)
)
SELECT 
    ci.full_name,
    ci.birth_date,
    ci.cd_gender,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    CustomerInfo ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ci.birth_date >= '1960-01-01'
GROUP BY 
    ci.full_name, ci.birth_date, ci.cd_gender, ci.ca_city, ci.ca_state, ci.ca_country
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 50;
