
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS address,
    ca.ca_city,
    ca.ca_state,
    (CASE 
        WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name 
        WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_first_name 
        ELSE c.c_first_name 
    END) AS formatted_salutation,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(ss.ss_sales_price) AS total_spent,
    COUNT(ss.ss_ticket_number) AS purchase_count,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer c 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
LEFT JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, 
    ca.ca_street_type, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_spent DESC 
LIMIT 100;
