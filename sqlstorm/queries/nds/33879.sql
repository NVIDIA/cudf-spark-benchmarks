WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_sales_price * ws_quantity AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS Sale_Rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(s.Total_Sales) AS Total_Customer_Sales,
        COUNT(s.Sale_Rank) AS Sale_Count
    FROM 
        customer c
    JOIN 
        SalesCTE s ON c.c_customer_sk = s.ws_item_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.Total_Customer_Sales,
        cs.Sale_Count,
        DENSE_RANK() OVER (ORDER BY cs.Total_Customer_Sales DESC) AS Sales_Rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.Total_Customer_Sales, 0) AS Total_Customer_Sales,
    COALESCE(tc.Sale_Count, 0) AS Sale_Count
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
    AND (tc.Total_Customer_Sales > 100 OR tc.Sale_Count > 5)
ORDER BY 
    tc.Sales_Rank
LIMIT 10;