
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Number_Of_Orders,
        AVG(ws.ws_sales_price) AS Average_Sales_Price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.Total_Sales,
        cs.Number_Of_Orders,
        cs.Average_Sales_Price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.Total_Sales > (SELECT AVG(Total_Sales) FROM CustomerSales)
),
SalesSummary AS (
    SELECT 
        hvc.cd_gender,
        hvc.cd_marital_status,
        hvc.cd_education_status,
        COUNT(*) AS Customer_Count,
        SUM(hvc.Total_Sales) AS Total_Sales_Sum,
        AVG(hvc.Average_Sales_Price) AS Average_Sales_Price
    FROM 
        HighValueCustomers hvc
    GROUP BY 
        hvc.cd_gender, hvc.cd_marital_status, hvc.cd_education_status
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.cd_education_status,
    ss.Customer_Count,
    ss.Total_Sales_Sum,
    ss.Average_Sales_Price,
    COALESCE((SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) AND wr.wr_returning_customer_sk IN (SELECT c_customer_sk FROM HighValueCustomers)), 0) AS Total_Returns
FROM 
    SalesSummary ss
ORDER BY 
    Total_Sales_Sum DESC;
