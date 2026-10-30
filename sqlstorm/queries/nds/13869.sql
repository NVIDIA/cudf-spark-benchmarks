
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
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
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
