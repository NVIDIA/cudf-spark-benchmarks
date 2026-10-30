
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ws.ws_quantity) AS total_quantity, 
    SUM(ws.ws_net_paid) AS total_sales, 
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
WHERE 
    dd.d_year = 2023 
    AND ca.ca_state IN ('NY', 'CA')
GROUP BY 
    ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(ws.ws_net_paid) > 100000
ORDER BY 
    total_sales DESC, 
    customer_count DESC;
