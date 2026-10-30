
SELECT 
    COUNT(*) AS total_sales, 
    SUM(ws_ext_sales_price) AS total_revenue, 
    AVG(ws_ext_sales_price) AS average_sales_price
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    item ON ws_item_sk = i_item_sk
WHERE 
    d_year = 2023 
    AND i_current_price > 0
GROUP BY 
    d_month_seq
ORDER BY 
    d_month_seq;
