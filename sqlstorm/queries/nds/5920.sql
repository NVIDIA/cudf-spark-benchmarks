
SELECT 
    c.c_customer_id AS customer_id,
    ca.ca_city AS customer_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_paid) AS average_order_value,
    d.d_year AS sales_year,
    p.p_promo_name AS promotional_campaign
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
    AND ca.ca_country = 'USA'
    AND ws.ws_sales_price > 100
GROUP BY 
    c.c_customer_id, 
    ca.ca_city, 
    d.d_year, 
    p.p_promo_name
ORDER BY 
    total_sales DESC, 
    order_count DESC;
