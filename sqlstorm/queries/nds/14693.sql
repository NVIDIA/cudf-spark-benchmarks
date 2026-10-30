
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS num_customers,
    AVG(CASE WHEN cd_gender = 'M' THEN cd_dep_count ELSE NULL END) AS avg_male_children,
    AVG(CASE WHEN cd_gender = 'F' THEN cd_dep_count ELSE NULL END) AS avg_female_children,
    SUM(ws_ext_sales_price) AS total_sales
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
