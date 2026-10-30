
SELECT 
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(ws.ws_sales_price) AS average_sales_price,
    MAX(ss.ss_net_profit) AS highest_net_profit
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_sk
ORDER BY 
    unique_customers DESC
LIMIT 100;
