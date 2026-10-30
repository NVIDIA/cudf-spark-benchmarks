
SELECT 
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023 
    AND ca.ca_state IN ('CA', 'NY', 'TX') 
    AND cd.cd_marital_status = 'M' 
GROUP BY 
    ca.ca_city, ca.ca_state, cd.cd_gender
ORDER BY 
    total_sales DESC
LIMIT 10;
