
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS average_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231 THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_2020,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231 THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_2021
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.cd_credit_rating = 'Good' 
    AND cd.cd_purchase_estimate > 1000
    AND d.d_year IN (2020, 2021)
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
ORDER BY 
    total_sales DESC
LIMIT 100;
