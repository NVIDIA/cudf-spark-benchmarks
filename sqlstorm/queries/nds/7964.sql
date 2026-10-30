
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_quantity) AS total_items_sold,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    EXTRACT(YEAR FROM d_date) AS sales_year
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    ca_state, sales_year
ORDER BY 
    total_net_profit DESC, ca_state;
