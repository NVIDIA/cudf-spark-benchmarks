
WITH  CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rn
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        cr_returning_customer_sk,
        total_returned,
        return_count
    FROM CustomerReturns
    WHERE rn <= 10
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_quantity) AS avg_quantity_per_order
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnCustomerSales AS (
    SELECT 
        wss.ws_bill_customer_sk,
        wss.total_orders,
        wss.total_spent,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.return_count, 0) AS return_count,
        wss.avg_quantity_per_order
    FROM WebSalesSummary wss
    LEFT JOIN TopReturningCustomers cr ON wss.ws_bill_customer_sk = cr.cr_returning_customer_sk
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    rcs.total_orders,
    rcs.total_spent,
    rcs.total_returned,
    rcs.return_count,
    rcs.avg_quantity_per_order,
    CASE 
        WHEN rcs.total_spent - rcs.total_returned > 1000 THEN 'High Value'
        WHEN rcs.total_spent = 0 AND rcs.return_count > 0 THEN 'Only Returns'
        ELSE 'Standard'
    END AS customer_value_category
FROM ReturnCustomerSales rcs
JOIN customer cu ON rcs.ws_bill_customer_sk = cu.c_customer_sk
WHERE rcs.total_orders IS NOT NULL
ORDER BY rcs.total_spent DESC NULLS LAST;
