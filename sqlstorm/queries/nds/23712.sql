
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender, c.c_birth_month ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS OrderCount,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS UniqueCustomers
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_month_seq
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS CustomerTotal
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.c_birth_month,
    rc.cd_gender,
    ms.TotalSales,
    ms.OrderCount,
    COALESCE(cs.CustomerTotal, 0) AS CustomerTotal,
    CASE 
        WHEN rc.PurchaseRank = 1 THEN 'Top Purchaser'
        ELSE 'Regular Customer'
    END AS CustomerType
FROM 
    RankedCustomers rc
LEFT JOIN 
    MonthlySales ms ON rc.c_birth_month = EXTRACT(MONTH FROM DATE '2002-10-01')
LEFT JOIN 
    CustomerSales cs ON rc.c_customer_sk = cs.c_customer_sk
WHERE 
    ms.TotalSales IS NOT NULL 
    AND rc.c_birth_month BETWEEN 1 AND 12
ORDER BY 
    rc.c_birth_month, rc.PurchaseRank;
