
SELECT 
    ca_state, 
    cd_gender, 
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_sales_price) AS average_sales_price,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity_sold
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
JOIN 
    web_sales ON ws_bill_customer_sk = c_customer_sk
JOIN 
    date_dim ON d_date_sk = ws_sold_date_sk
JOIN 
    item ON i_item_sk = ws_item_sk
WHERE 
    d_year = 2023 
    AND cd_gender = 'F'
GROUP BY 
    ca_state, cd_gender
ORDER BY 
    total_net_profit DESC
LIMIT 10;
