
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    d.d_year AS sales_year,
    ca.ca_city AS customer_city,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned_quantity,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN 
    store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
WHERE 
    d.d_year BETWEEN 2022 AND 2023
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    d.d_year,
    ca.ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 100;
