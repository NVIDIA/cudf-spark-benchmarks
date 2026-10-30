
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_revenue,
    AVG(ws.ws_net_profit) AS average_web_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    wd.w_warehouse_id,
    inv.inv_quantity_on_hand,
    dt.d_year,
    dt.d_month_seq,
    dt.d_week_seq
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    inventory inv ON ws.ws_item_sk = inv.inv_item_sk
JOIN 
    warehouse wd ON inv.inv_warehouse_sk = wd.w_warehouse_sk
JOIN 
    date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
WHERE 
    dt.d_year BETWEEN 2022 AND 2023
    AND wd.w_state = 'CA'
GROUP BY 
    c.c_customer_id, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    wd.w_warehouse_id,
    inv.inv_quantity_on_hand,
    dt.d_year,
    dt.d_month_seq,
    dt.d_week_seq
ORDER BY 
    total_web_revenue DESC, 
    total_web_sales DESC
LIMIT 100;
