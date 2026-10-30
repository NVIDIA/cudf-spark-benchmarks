
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_refunded
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(cs.total_profit, 0) AS total_profit
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN CustomerSales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    WHERE COALESCE(cr.total_returned, 0) > 0 OR COALESCE(cs.total_orders, 0) > 10
),
AggregatedCustomerData AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ROW_NUMBER() OVER (ORDER BY tc.total_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY tc.total_returned DESC) AS return_rank
    FROM TopCustomers tc
)
SELECT 
    acd.c_customer_sk,
    acd.c_first_name,
    acd.c_last_name,
    acd.profit_rank,
    acd.return_rank,
    (acd.profit_rank + acd.return_rank) AS combined_rank,
    CASE 
        WHEN acd.profit_rank <= 10 THEN 'High Value'
        WHEN acd.return_rank <= 10 THEN 'Return Frequent'
        ELSE 'Regular'
    END AS customer_segment
FROM AggregatedCustomerData acd
WHERE acd.profit_rank <= 20 OR acd.return_rank <= 20
ORDER BY combined_rank
LIMIT 50;
