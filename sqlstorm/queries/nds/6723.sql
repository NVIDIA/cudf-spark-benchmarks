
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_profit) AS total_net_profit,
    d.d_year,
    da.ca_country,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer_address da ON c.c_current_addr_sk = da.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    d.d_year = 2023
    AND da.ca_country = 'USA'
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, da.ca_country
HAVING 
    SUM(ss.ss_net_profit) > 1000
ORDER BY 
    total_net_profit DESC
LIMIT 50;
