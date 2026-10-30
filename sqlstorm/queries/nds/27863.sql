
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_value
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_customer_sk
),
TopCustomers AS (
    SELECT
        r.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_returns,
        r.total_return_value,
        RANK() OVER (ORDER BY r.total_return_value DESC) AS rank
    FROM RankedReturns r
    JOIN customer c ON r.sr_customer_sk = c.c_customer_sk
)
SELECT
    tc.sr_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_return_value,
    CASE
        WHEN tc.rank <= 10 THEN 'Top 10 Customers'
        WHEN tc.rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM TopCustomers tc
ORDER BY tc.rank;
