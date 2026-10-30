
SELECT 
    COUNT(*) AS Total_Sales, 
    SUM(ss_net_paid) AS Total_Revenue, 
    AVG(ss_net_paid) AS Avg_Sale_Amount, 
    ss_store_sk
FROM 
    store_sales
WHERE 
    ss_sold_date_sk BETWEEN 1000 AND 2000 
GROUP BY 
    ss_store_sk
ORDER BY 
    Total_Revenue DESC
LIMIT 10;
