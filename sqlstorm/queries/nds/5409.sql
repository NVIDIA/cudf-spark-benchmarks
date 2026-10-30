
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
    SUM(ss_net_profit) AS total_net_profit,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ss_sales_price) AS median_sales_price
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk 
JOIN 
    date_dim ON ss_sold_date_sk = d_date_sk 
JOIN 
    item ON ss_item_sk = i_item_sk 
WHERE 
    d_year = 2023 AND 
    cd_gender = 'F' AND 
    ca_country = 'USA' 
GROUP BY 
    ca_state 
ORDER BY 
    total_net_profit DESC
LIMIT 10;
