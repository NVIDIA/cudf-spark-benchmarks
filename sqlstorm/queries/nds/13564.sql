
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS Unique_Customers,
    SUM(ws.ws_sales_price) AS Total_Sales_Amount,
    AVG(cd.cd_purchase_estimate) AS Average_Purchase_Estimate,
    d.d_year AS Sales_Year
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
