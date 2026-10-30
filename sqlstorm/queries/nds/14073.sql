
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    p.p_promo_name,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 2451545 AND 2454545
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, p.p_promo_name
ORDER BY 
    total_sales DESC
LIMIT 10;
