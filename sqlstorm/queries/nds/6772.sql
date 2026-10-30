
SELECT 
    c.c_customer_id,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages_visited,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_given
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    d.d_year
HAVING 
    SUM(ws.ws_net_paid_inc_tax) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
