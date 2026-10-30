
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS RankByPurchaseEstimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        sd.TotalSales,
        sd.OrderCount,
        CASE 
            WHEN sd.TotalSales >= 1000 THEN 'High Value'
            WHEN sd.TotalSales >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS CustomerValue
    FROM 
        CustomerSummary cs
    JOIN 
        SalesData sd ON cs.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        cs.RankByPurchaseEstimate <= 10
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    COALESCE(t.CustomerValue, 'No Sales') AS CustomerCategory,
    COUNT(DISTINCT t.c_customer_sk) AS UniqueCustomers,
    AVG(t.TotalSales) AS AvgSales,
    SUM(t.TotalSales) AS TotalRevenue,
    SUM(t.OrderCount) AS TotalOrders
FROM 
    TopCustomers t
LEFT JOIN 
    store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    t.c_first_name, 
    t.c_last_name, 
    COALESCE(t.CustomerValue, 'No Sales')
ORDER BY 
    TotalRevenue DESC
LIMIT 50;
