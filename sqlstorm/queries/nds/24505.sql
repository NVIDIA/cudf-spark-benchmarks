
WITH  HierarchicalCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'NY'
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'NY')
)
SELECT 
    m.c_customer_id,
    m.ca_city,
    STRING_AGG(DISTINCT m.cd_gender || ' ' || m.cd_marital_status, ', ') AS demographics,
    COUNT(DISTINCT CASE WHEN m.rn <= 3 THEN m.c_customer_id END) AS top_customers,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
    COUNT(DISTINCT CASE WHEN ws.ws_ship_date_sk IS NULL OR ws.ws_net_paid = 0 THEN ws.ws_order_number END) AS total_returns
FROM 
    HierarchicalCTE m
LEFT JOIN 
    web_sales ws ON m.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    m.c_customer_id, m.ca_city
HAVING 
    COUNT(DISTINCT m.c_customer_id) > 1
ORDER BY 
    total_profit DESC
LIMIT 10;
