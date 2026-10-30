
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store s ON ws.ws_ship_addr_sk = s.s_store_sk
WHERE 
    cd.cd_gender = 'M' 
    AND cd.cd_marital_status = 'M' 
    AND d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, d.d_week_seq
ORDER BY 
    total_net_profit DESC
LIMIT 100;
