
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_net_profit) AS average_profit
FROM 
    web_sales
JOIN 
    customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
JOIN 
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
WHERE 
    date_dim.d_year = 2023
GROUP BY 
    customer.c_birth_country
ORDER BY 
    total_sales DESC
LIMIT 10;
