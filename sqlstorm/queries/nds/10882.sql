
SELECT 
    COUNT(*) AS total_orders, 
    SUM(ws_ext_sales_price) AS total_revenue, 
    AVG(ws_sales_price) AS average_item_price
FROM 
    web_sales 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
WHERE 
    d_year = 2023
GROUP BY 
    c_customer_id 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
