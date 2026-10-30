
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    cd_gender, 
    d_year 
FROM 
    web_sales 
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk 
GROUP BY 
    cd_gender, d_year 
ORDER BY 
    total_sales DESC 
LIMIT 10;
