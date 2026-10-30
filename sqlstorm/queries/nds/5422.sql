
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN d.d_date_sk AND d.d_date_sk + 30 THEN ws.ws_sales_price ELSE 0 END) AS total_sales_last_30_days,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN d.d_date_sk + 31 AND d.d_date_sk + 60 THEN ws.ws_sales_price ELSE 0 END) AS total_sales_next_30_days,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_date_sk
ORDER BY 
    total_sales_last_30_days DESC, average_profit DESC
LIMIT 100;
