
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
        AND ws_quantity > 0
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(CASE WHEN r.rank = 1 THEN r.ws_sales_price * r.ws_quantity ELSE 0 END) AS Top_Sales,
        COUNT(DISTINCT r.ws_item_sk) AS Total_Items_Sold
    FROM 
        CustomerInfo c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighestSales AS (
    SELECT 
        c.*, 
        COALESCE(ss.Top_Sales, 0) AS Top_Sales
    FROM 
        CustomerInfo c
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.c_customer_sk
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.Top_Sales,
    CASE 
        WHEN hs.Top_Sales > 1000 THEN 'High Roller'
        WHEN hs.Top_Sales > 500 THEN 'Moderate Spender'
        ELSE 'Casual Shopper' 
    END AS Customer_Type,
    COUNT(r.ws_item_sk) FILTER (WHERE r.ws_sales_price > 20) AS High_Value_Items,
    COUNT(r.ws_item_sk) FILTER (WHERE r.ws_sales_price <= 20) AS Low_Value_Items
FROM 
    HighestSales hs
LEFT JOIN 
    web_sales r ON hs.c_customer_sk = r.ws_bill_customer_sk
GROUP BY 
    hs.c_first_name, hs.c_last_name, hs.Top_Sales
HAVING 
    hs.Top_Sales > (SELECT AVG(Top_Sales) FROM SalesSummary)
ORDER BY 
    hs.Top_Sales DESC
LIMIT 10;
