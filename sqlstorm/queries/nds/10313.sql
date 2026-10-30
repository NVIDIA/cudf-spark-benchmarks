
SELECT 
    c.c_customer_id, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_sales_price) AS total_sales_amount, 
    AVG(ss.ss_sales_price) AS avg_sales_price, 
    CD.cd_gender 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk 
WHERE 
    CD.cd_marital_status = 'M' 
    AND CD.cd_gender = 'F' 
GROUP BY 
    c.c_customer_id, CD.cd_gender 
ORDER BY 
    total_sales_amount DESC 
LIMIT 100;
