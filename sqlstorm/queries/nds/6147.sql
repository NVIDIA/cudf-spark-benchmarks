
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
JOIN 
    time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE 
    dd.d_year = 2022 
    AND ca.ca_state = 'CA'
    AND ws.ws_sales_price > 100
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY 
    total_sales DESC
LIMIT 100;
