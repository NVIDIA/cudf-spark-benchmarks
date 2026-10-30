
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
    AND cd.cd_gender IN ('F', 'M')
    AND ws.ws_sold_date_sk >= (
        SELECT 
            MAX(d.d_date_sk) - 365 
        FROM 
            date_dim d 
    )
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_web_sales DESC
LIMIT 100;
