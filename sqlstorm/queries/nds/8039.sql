
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    sm.sm_carrier,
    ca.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023 
    AND w.w_country = 'USA'
    AND sm.sm_carrier IN ('FedEx', 'UPS')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    d.d_month_seq, 
    w.w_warehouse_name, 
    sm.sm_carrier, 
    ca.ca_city, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    hd.hd_buy_potential
ORDER BY 
    total_spent DESC
LIMIT 100;
