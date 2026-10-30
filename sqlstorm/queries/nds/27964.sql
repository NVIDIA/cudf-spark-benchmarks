
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type || 
    CASE 
        WHEN ca.ca_suite_number IS NOT NULL THEN ' Suite ' || ca.ca_suite_number 
        ELSE '' 
    END AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_date AS purchase_date,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_order_value
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND cd.cd_purchase_estimate > 1000
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, 
    ca.ca_street_type, ca.ca_suite_number, cd.cd_gender, cd.cd_marital_status, d.d_date
ORDER BY 
    total_spent DESC
LIMIT 10;
