
WITH CustomerSales AS (
    SELECT
        C.c_customer_id,
        SUM(CASE WHEN WS.ws_sold_date_sk IS NOT NULL THEN WS.ws_net_profit ELSE 0 END) AS Total_Web_Sales,
        SUM(CASE WHEN CS.cs_sold_date_sk IS NOT NULL THEN CS.cs_net_profit ELSE 0 END) AS Total_Catalog_Sales,
        SUM(CASE WHEN SS.ss_sold_date_sk IS NOT NULL THEN SS.ss_net_profit ELSE 0 END) AS Total_Store_Sales
    FROM customer C
    LEFT JOIN web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
    LEFT JOIN catalog_sales CS ON C.c_customer_sk = CS.cs_ship_customer_sk
    LEFT JOIN store_sales SS ON C.c_customer_sk = SS.ss_customer_sk
    GROUP BY C.c_customer_id
),
SalesSummary AS (
    SELECT
        CASE 
            WHEN Total_Web_Sales > Total_Catalog_Sales AND Total_Web_Sales > Total_Store_Sales THEN 'Web'
            WHEN Total_Catalog_Sales > Total_Web_Sales AND Total_Catalog_Sales > Total_Store_Sales THEN 'Catalog'
            ELSE 'Store'
        END AS Preferred_Channel,
        COUNT(c_customer_id) AS Customer_Count,
        SUM(Total_Web_Sales) AS Total_Web_Sales_Sum,
        SUM(Total_Catalog_Sales) AS Total_Catalog_Sales_Sum,
        SUM(Total_Store_Sales) AS Total_Store_Sales_Sum
    FROM CustomerSales
    GROUP BY Preferred_Channel
)
SELECT 
    Preferred_Channel,
    Customer_Count,
    Total_Web_Sales_Sum,
    Total_Catalog_Sales_Sum,
    Total_Store_Sales_Sum,
    RANK() OVER (ORDER BY Total_Web_Sales_Sum DESC) AS Web_Sales_Rank,
    RANK() OVER (ORDER BY Total_Catalog_Sales_Sum DESC) AS Catalog_Sales_Rank,
    RANK() OVER (ORDER BY Total_Store_Sales_Sum DESC) AS Store_Sales_Rank
FROM SalesSummary
ORDER BY Customer_Count DESC;
