
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451201 AND 2451231
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_sales_price) AS TotalSales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.TotalOrders,
        cs.TotalSales,
        CASE 
            WHEN cs.TotalSales IS NULL THEN 'No Sales'
            WHEN cs.TotalSales < 100 THEN 'Low Value'
            WHEN cs.TotalSales BETWEEN 100 AND 500 THEN 'Medium Value'
            ELSE 'High Value'
        END AS ValueCategory
    FROM 
        CustomerSummary cs
)
SELECT 
    s.CustomerName,
    s.TotalOrders,
    s.TotalSales,
    r.SalesRank,
    sa.ValueCategory
FROM 
    (SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS CustomerName,
        cs.TotalOrders,
        cs.TotalSales,
        cs.c_customer_sk
    FROM 
        CustomerSummary cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk) s
LEFT JOIN 
    RankedSales r ON s.c_customer_sk = r.ws_bill_customer_sk AND r.SalesRank = 1
JOIN 
    SalesAnalysis sa ON s.c_customer_sk = sa.c_customer_sk
WHERE 
    sa.ValueCategory != 'No Sales'
ORDER BY 
    sa.ValueCategory, s.TotalSales DESC;
