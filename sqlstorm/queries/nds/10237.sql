
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    AVG(ws_net_profit) AS average_profit
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
WHERE 
    d_year = 2023 AND 
    cd_gender = 'F'
GROUP BY 
    d_month_seq
ORDER BY 
    total_sales DESC;
