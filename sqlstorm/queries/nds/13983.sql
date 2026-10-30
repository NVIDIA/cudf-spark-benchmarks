
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(s.ws_net_paid) AS total_sales,
    COUNT(DISTINCT o.ws_order_number) AS total_orders
FROM 
    customer c
JOIN 
    web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    (SELECT 
        ws_bill_customer_sk,
        ws_order_number
     FROM 
        web_sales
     WHERE 
        ws_sold_date_sk BETWEEN 2451906 AND 2451946) o ON s.ws_bill_customer_sk = o.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 100;
