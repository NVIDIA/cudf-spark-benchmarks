
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_sk) AS total_customers, 
    SUM(ws.ws_net_profit) AS total_net_profit, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(sr.sr_return_quantity) AS total_returned_items,
    CAST(d.d_date AS DATE) AS sales_date
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    d.d_year = 2022 
    AND ca.ca_country = 'USA'
GROUP BY 
    ca.ca_city, d.d_date, cd.cd_purchase_estimate, ws.ws_net_profit
ORDER BY 
    total_net_profit DESC, total_customers DESC
LIMIT 50;
