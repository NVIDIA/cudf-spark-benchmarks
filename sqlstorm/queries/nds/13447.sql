
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS number_of_orders,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
