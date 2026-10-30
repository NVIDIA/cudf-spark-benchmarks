
SELECT 
    ca.ca_city, 
    cd.cd_gender, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count, 
    SUM(ss.ss_sales_price) AS total_sales, 
    SUM(ss.ss_net_profit) AS total_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca.ca_city, cd.cd_gender
ORDER BY 
    total_sales DESC
LIMIT 100;
