
SELECT 
    SUM(ws_sales_price) AS Total_Sales, 
    COUNT(DISTINCT ws_order_number) AS Total_Orders, 
    AVG(ws_sales_price) AS Average_Sale_Price 
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim) 
GROUP BY 
    ws_item_sk 
ORDER BY 
    Total_Sales DESC 
LIMIT 10;
