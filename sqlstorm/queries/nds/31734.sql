
WITH  CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM
        customer AS c
    LEFT JOIN
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING
        COUNT(sr_item_sk) > 0
),
TopCustomers AS (
    SELECT
        c_sk.c_customer_sk,
        c_sk.c_first_name,
        c_sk.c_last_name,
        c_sk.total_returns,
        c_sk.total_returned_value,
        RANK() OVER (ORDER BY c_sk.total_returned_value DESC) AS rank
    FROM
        CustomerReturns AS c_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_returned_value,
    NULLIF(tc.total_returned_value / NULLIF(tc.total_returns, 0), 0) AS avg_return_value,
    (SELECT AVG(total_returns) FROM TopCustomers WHERE rank <= 10) AS avg_top_10_returns,
    (SELECT COUNT(*) FROM web_sales AS ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS total_web_sales_count
FROM
    TopCustomers AS tc
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_returned_value DESC
LIMIT 5;
