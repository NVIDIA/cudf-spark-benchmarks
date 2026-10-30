
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT customer.c_customer_id) AS total_customers, 
    SUM(ws_quantity) AS total_quantity_sold, 
    SUM(ws_net_profit) AS total_net_profit, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate 
FROM 
    customer_address 
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk 
JOIN 
    web_sales ON web_sales.ws_bill_customer_sk = customer.c_customer_sk 
JOIN 
    customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk 
JOIN 
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk 
WHERE 
    date_dim.d_year = 2022 
    AND cd_gender = 'F' 
    AND cd_marital_status = 'M' 
GROUP BY 
    ca_city, 
    ca_state 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
