
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ws.ws_sales_price) AS total_sales, 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year BETWEEN 2021 AND 2022 
    AND ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_sales DESC, 
    unique_customers DESC
LIMIT 10;
