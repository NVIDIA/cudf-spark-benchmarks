
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS GenderRank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM RankedCustomers rc
    WHERE rc.GenderRank <= 5
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(ss.TotalSales, 0) AS TotalSales,
        ss.OrderCount
    FROM TopCustomers tc
    LEFT JOIN SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.TotalSales,
    cs.OrderCount,
    CASE 
        WHEN cs.TotalSales > 1000 THEN 'High Value'
        WHEN cs.TotalSales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerValueSegment,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = cs.c_customer_sk) AS StorePurchaseCount,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_sk) AS WebPurchaseCount
FROM CustomerSales cs
ORDER BY cs.TotalSales DESC
LIMIT 10;
