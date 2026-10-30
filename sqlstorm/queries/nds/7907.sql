
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_net_paid_inc_tax) AS avg_net_income
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
    AND cd.cd_gender = 'F'
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 100
ORDER BY 
    total_net_profit DESC;
