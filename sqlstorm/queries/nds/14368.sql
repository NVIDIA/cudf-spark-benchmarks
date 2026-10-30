
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    i.i_product_name,
    ws.ws_sales_price,
    ws.ws_quantity,
    d.d_date,
    sm.sm_type
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date, c.c_last_name, c.c_first_name;
