
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    STRING_AGG(DISTINCT sm.sm_carrier, ', ') AS shipping_carriers_used,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
