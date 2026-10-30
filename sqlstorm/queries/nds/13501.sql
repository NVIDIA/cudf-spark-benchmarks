
SELECT 
    AVG(ws_net_profit) AS average_net_profit,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ws_quantity) AS total_quantity_sold,
    ws_sold_date_sk
FROM 
    web_sales
JOIN 
    customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
WHERE 
    ws_sold_date_sk BETWEEN 2450000 AND 2450600
    AND ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'Regular')
GROUP BY 
    ws_sold_date_sk;
