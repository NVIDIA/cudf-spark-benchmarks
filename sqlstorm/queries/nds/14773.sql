
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    i.i_item_id, 
    i.i_item_desc, 
    ss.ss_quantity, 
    ss.ss_sales_price, 
    ss.ss_ext_sales_price, 
    ss.ss_net_profit 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk 
WHERE 
    c.c_birth_year >= 1980 
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500 
ORDER BY 
    ss.ss_net_profit DESC 
LIMIT 100;
