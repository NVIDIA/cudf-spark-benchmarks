
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    AVG(ws.ws_net_profit) AS average_web_profit,
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk 
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk 
WHERE 
    d.d_year = 2023 
AND 
    c.c_preferred_cust_flag = 'Y' 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, w.w_warehouse_name, sm.sm_type 
ORDER BY 
    total_sales_amount DESC 
LIMIT 100;
