
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_quantity) AS total_quantity,
    w.w_warehouse_name,
    d.d_year,
    a.hd_income_band_sk,
    a.hd_buy_potential
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    household_demographics a ON cd.cd_demo_sk = a.hd_demo_sk
WHERE 
    d.d_year BETWEEN 2022 AND 2023
    AND ws.ws_sales_price > 20
GROUP BY 
    c.c_customer_id, ca.ca_city, cd.cd_marital_status, w.w_warehouse_name, d.d_year, a.hd_income_band_sk, a.hd_buy_potential
ORDER BY 
    total_profit DESC, total_orders DESC
LIMIT 100;
