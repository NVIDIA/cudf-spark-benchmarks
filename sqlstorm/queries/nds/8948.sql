
SELECT 
    c.c_customer_id,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023 
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status, d.d_year, w.w_warehouse_name, sm.sm_type
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC;
