
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS Total_Sales,
        COUNT(DISTINCT ss.ss_ticket_number) + COUNT(DISTINCT ws.ws_order_number) AS Total_Orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
SalesSummary AS (
    SELECT
        cd_gender,
        COUNT(c_customer_id) AS Customer_Count,
        SUM(Total_Sales) AS Total_Sales,
        AVG(Total_Sales) AS Avg_Sales_Per_Customer,
        SUM(Total_Orders) AS Total_Orders,
        AVG(Total_Orders) AS Avg_Orders_Per_Customer
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender
)
SELECT 
    ss.cd_gender,
    ss.Customer_Count,
    ss.Total_Sales,
    ss.Avg_Sales_Per_Customer,
    ss.Total_Orders,
    ss.Avg_Orders_Per_Customer,
    CASE 
        WHEN ss.Avg_Sales_Per_Customer > 1000 THEN 'High Value'
        WHEN ss.Avg_Sales_Per_Customer BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value_Category
FROM 
    SalesSummary ss
ORDER BY 
    ss.Total_Sales DESC;
