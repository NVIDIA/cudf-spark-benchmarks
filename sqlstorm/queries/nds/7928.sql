
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS total_orders,
    d.d_year,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    w.w_warehouse_name,
    sm.sm_carrier
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_year, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, w.w_warehouse_name, sm.sm_carrier
ORDER BY 
    total_sales DESC
LIMIT 100;
