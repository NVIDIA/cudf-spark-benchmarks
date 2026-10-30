
WITH RankedReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS total_return_count,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rank
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        r.cr_returning_customer_sk,
        r.total_returned_quantity,
        r.total_return_count,
        COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown') AS customer_name,
        COALESCE(c.c_email_address, 'No Email') AS email,
        CASE
            WHEN r.total_returned_quantity IS NULL THEN 'No Returns'
            WHEN r.total_returned_quantity = 0 THEN 'No Items Returned'
            ELSE 'Returned Items'
        END AS return_status
    FROM RankedReturns r
    LEFT JOIN customer c ON r.cr_returning_customer_sk = c.c_customer_sk
    WHERE r.rank <= 10
),
SalesAnalysis AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_items_sold,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_profit) > 0
)
SELECT
    tc.customer_name,
    tc.email,
    tc.total_returned_quantity,
    tc.total_return_count,
    COALESCE(sa.total_net_profit, 0) AS total_net_profit,
    COALESCE(sa.total_items_sold, 0) AS total_items_sold,
    COALESCE(sa.order_count, 0) AS order_count,
    CASE 
        WHEN tc.total_returned_quantity > COALESCE(sa.total_items_sold, 0) THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_status
FROM TopReturningCustomers tc
LEFT JOIN SalesAnalysis sa ON tc.cr_returning_customer_sk = sa.ws_bill_customer_sk
WHERE (tc.return_status = 'Returned Items' OR sa.total_net_profit IS NOT NULL)
ORDER BY tc.total_returned_quantity DESC, sa.total_net_profit DESC;
