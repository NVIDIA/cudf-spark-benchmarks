
SELECT 
    s.s_store_id, 
    SUM(ws.ws_quantity) AS total_quantity, 
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    store s
JOIN 
    web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk 
WHERE 
    ws.ws_sold_date_sk BETWEEN 2457304 AND 2457308 
GROUP BY 
    s.s_store_id
ORDER BY 
    total_sales DESC;
