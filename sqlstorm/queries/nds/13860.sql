
SELECT 
    c.c_customer_id, 
    ca.ca_street_name, 
    ca.ca_city, 
    p.p_promo_name, 
    ws.ws_sales_price, 
    SUM(ss.ss_quantity) AS total_quantity_sold
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_city = 'San Francisco' 
    AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
GROUP BY 
    c.c_customer_id, ca.ca_street_name, ca.ca_city, p.p_promo_name, ws.ws_sales_price
ORDER BY 
    total_quantity_sold DESC
LIMIT 100;
