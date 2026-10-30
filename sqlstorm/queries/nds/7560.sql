
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_sales_price) AS total_sales, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    d.d_year, 
    p.p_promo_name, 
    sm.sm_carrier
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    d.d_year, 
    p.p_promo_name, 
    sm.sm_carrier
ORDER BY 
    total_sales DESC
LIMIT 100;
