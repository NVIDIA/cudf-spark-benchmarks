
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    d.d_date AS sale_date,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
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
    AND (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, cd.cd_gender, 
    cd.cd_marital_status, cd.cd_education_status, 
    cd.cd_purchase_estimate, cd.cd_credit_rating, d.d_date
ORDER BY 
    total_sales DESC, order_count DESC
LIMIT 100;
