
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns_count,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq,
    w.w_warehouse_id,
    sm.sm_type AS shipping_method,
    cd.cd_gender,
    hd.hd_income_band_sk
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq,
    w.w_warehouse_id,
    sm.sm_type,
    cd.cd_gender,
    hd.hd_income_band_sk
ORDER BY 
    total_net_profit DESC
LIMIT 100;
