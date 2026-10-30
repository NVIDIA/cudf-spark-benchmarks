
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    AVG(ws_net_profit) AS average_profit
FROM 
    web_sales
JOIN 
    item ON ws_item_sk = i_item_sk
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
WHERE 
    c_birth_year BETWEEN 1980 AND 1990
    AND ws_sold_date_sk >= 20230101
    AND ws_sold_date_sk <= 20231231
GROUP BY 
    c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
