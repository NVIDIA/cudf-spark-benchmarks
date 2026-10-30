
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS CustomerSK, 
        SUM(ws_sales_price) AS TotalSales, 
        COUNT(ws_order_number) AS OrderCount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk AS CustomerSK, 
        cd.cd_gender AS Gender, 
        cd.cd_marital_status AS MaritalStatus, 
        cd.cd_purchase_estimate AS PurchaseEstimate, 
        ca.ca_city AS City, 
        ca.ca_state AS State
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), RankedSales AS (
    SELECT 
        ci.CustomerSK, 
        ci.Gender, 
        ci.MaritalStatus, 
        ci.PurchaseEstimate, 
        ci.City, 
        ci.State, 
        sd.TotalSales, 
        sd.OrderCount,
        DENSE_RANK() OVER (PARTITION BY ci.Gender ORDER BY sd.TotalSales DESC) AS GenderRank
    FROM 
        SalesData sd
    JOIN 
        CustomerInfo ci ON sd.CustomerSK = ci.CustomerSK
)
SELECT 
    Gender, 
    AVG(TotalSales) AS AvgTotalSales, 
    AVG(OrderCount) AS AvgOrderCount, 
    COUNT(*) AS CustomerCount
FROM 
    RankedSales
WHERE 
    GenderRank <= 10
GROUP BY 
    Gender
ORDER BY 
    AvgTotalSales DESC;
