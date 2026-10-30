
SELECT 
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(i.i_current_price) AS max_item_price,
    MIN(i.i_current_price) AS min_item_price
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ws.ws_sold_date_sk > 2400 
GROUP BY 
    c.c_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
