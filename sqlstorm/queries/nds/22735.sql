
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as SalesRank
    FROM web_sales ws
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS TotalReturnQuantity,
        SUM(cr.cr_return_amount) AS TotalReturnAmount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_sales_price,
        COALESCE(tr.TotalReturnQuantity, 0) AS TotalReturnQuantity,
        COALESCE(tr.TotalReturnAmount, 0) AS TotalReturnAmount
    FROM RankedSales rs
    LEFT JOIN TotalReturns tr ON rs.ws_item_sk = tr.cr_item_sk 
    WHERE rs.SalesRank = 1
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_paid), 0) AS TotalSpent,
        COUNT(DISTINCT ws.ws_order_number) AS OrderCount
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        cs.TotalSpent,
        cs.OrderCount,
        ROW_NUMBER() OVER (ORDER BY cs.TotalSpent DESC) AS SpendingRank
    FROM CustomerSpending cs
    JOIN customer c ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerSpending)
),
FinalReport AS (
    SELECT 
        swr.ws_item_sk,
        swr.ws_order_number,
        swr.ws_quantity,
        swr.TotalReturnQuantity,
        swr.TotalReturnAmount,
        hvc.TotalSpent,
        hvc.OrderCount
    FROM SalesWithReturns swr
    JOIN HighValueCustomers hvc ON hvc.c_customer_sk = swr.ws_order_number
)
SELECT 
    fr.ws_item_sk,
    fr.ws_order_number,
    fr.ws_quantity,
    fr.TotalReturnQuantity,
    fr.TotalReturnAmount,
    fr.TotalSpent,
    fr.OrderCount
FROM FinalReport fr
WHERE EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_customer_sk = fr.ws_order_number
    AND c.c_birth_month = fr.ws_quantity
) 
AND fr.TotalReturnQuantity IS NOT NULL
ORDER BY fr.TotalSpent DESC, fr.TotalReturnAmount ASC
LIMIT 100;
