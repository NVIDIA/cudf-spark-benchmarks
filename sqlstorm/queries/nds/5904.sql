
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    d.d_year,
    d.d_month_seq,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2023 AND 
    ca.ca_state IN ('CA', 'NY', 'TX') AND 
    cd.cd_credit_rating = 'Good'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, ca.ca_state
ORDER BY 
    total_net_paid DESC, order_count DESC
LIMIT 100;
