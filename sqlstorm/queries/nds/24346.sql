
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS Gender_Rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count,
        AVG(ws_net_paid) AS Avg_Transaction_Value
    FROM web_sales 
    GROUP BY ws_bill_customer_sk
),
Customer_Sales AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ss.Total_Sales,
        ss.Order_Count,
        ss.Avg_Transaction_Value,
        rc.Gender_Rank
    FROM Ranked_Customers rc
    LEFT JOIN Sales_Summary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.Total_Sales, 0) AS Total_Sales,
    COALESCE(cs.Order_Count, 0) AS Order_Count,
    COALESCE(cs.Avg_Transaction_Value, 0) AS Avg_Transaction_Value,
    CASE 
        WHEN cs.Order_Count IS NULL THEN 'No Orders'
        WHEN cs.Total_Sales > 1000 THEN 'High Value Customer'
        WHEN cs.Total_Sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS Customer_Type,
    RANK() OVER (ORDER BY COALESCE(cs.Total_Sales, 0) DESC) AS Sales_Rank
FROM Customer_Sales cs
WHERE cs.Gender_Rank <= 10
UNION ALL
SELECT 
    'Unknown' AS c_first_name,
    'Customer' AS c_last_name,
    0 AS Total_Sales,
    0 AS Order_Count,
    0 AS Avg_Transaction_Value,
    'No Orders' AS Customer_Type,
    NULL AS Sales_Rank
WHERE NOT EXISTS (SELECT 1 FROM Customer_Sales);
