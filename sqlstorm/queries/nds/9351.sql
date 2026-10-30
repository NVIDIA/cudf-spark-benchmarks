
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(ws.ws_sold_date_sk) AS last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    w.w_warehouse_name
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, d.d_year, w.w_warehouse_name
HAVING 
    SUM(ws.ws_ext_sales_price) > 5000
ORDER BY 
    total_sales DESC
LIMIT 100;
