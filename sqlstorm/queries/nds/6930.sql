
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    SUM(ws.ws_quantity) AS total_quantity_sold, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    AVG(ws.ws_sales_price) AS avg_sales_price, 
    MAX(ws.ws_ship_date_sk) AS last_shipped_date, 
    COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023 
    AND ca.ca_state = 'CA' 
    AND ws.ws_ship_mode_sk IN (
        SELECT sm.sm_ship_mode_sk 
        FROM ship_mode sm 
        WHERE sm.sm_type = 'Ground'
    )
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
