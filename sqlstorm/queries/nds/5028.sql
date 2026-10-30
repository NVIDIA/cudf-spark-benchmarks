
WITH ItemSales AS (
    SELECT 
        ws.ws_item_sk AS Item_SK,
        SUM(ws.ws_sales_price) AS Total_Sales,
        COUNT(ws.ws_order_number) AS Order_Count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk AS Customer_SK,
        cd.cd_gender AS Gender,
        cd.cd_marital_status AS Marital_Status,
        SUM(cs.cs_sales_price) AS Total_Sales,
        COUNT(cs.cs_order_number) AS Order_Count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        it.Item_SK,
        it.Total_Sales,
        it.Order_Count,
        cs.Gender,
        cs.Marital_Status,
        ROW_NUMBER() OVER (PARTITION BY cs.Gender ORDER BY it.Total_Sales DESC) AS Gender_Rank
    FROM 
        ItemSales it
    JOIN 
        CustomerStats cs ON it.Item_SK = cs.Customer_SK
)

SELECT 
    Item_SK,
    Total_Sales,
    Order_Count,
    Gender,
    Marital_Status,
    Gender_Rank
FROM 
    SalesSummary
WHERE 
    Gender_Rank <= 10
ORDER BY 
    Gender, Total_Sales DESC;
