
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
           CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
    cd.cd_demo_sk,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    d.d_year, 
    d.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_items_purchased
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
    d.d_year = 2022
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
    ca.ca_suite_number, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year, d.d_month_seq
ORDER BY 
    total_profit DESC
LIMIT 100;
