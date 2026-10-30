
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND cd.cd_marital_status = 'M'
    AND ws.ws_sold_date_sk BETWEEN 15000 AND 15030
GROUP BY 
    c.c_customer_id, ca.ca_city, cd.cd_gender
ORDER BY 
    total_profit DESC
LIMIT 100;
