
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    i.i_item_id,
    ws.ws_sales_price,
    ss.ss_quantity,
    ss.ss_net_paid
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    ss.ss_net_paid DESC
LIMIT 100;
