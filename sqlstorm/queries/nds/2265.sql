
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COUNT(cr.cr_order_number) AS total_returns
    FROM
        customer c
    LEFT JOIN
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_amount,
        cr.total_returns,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rnk
    FROM
        CustomerReturns cr
    INNER JOIN
        customer c ON c.c_customer_sk = cr.c_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_return_amount,
    tc.total_returns,
    (
        SELECT
            COUNT(DISTINCT ws.ws_order_number)
        FROM
            web_sales ws
        WHERE
            ws.ws_bill_customer_sk = tc.c_customer_sk
            AND ws.ws_sales_price > 100
    ) AS high_value_orders,
    (SELECT AVG(ws.ws_net_paid_inc_tax)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS avg_net_paid_inc_tax
FROM
    TopCustomers tc
WHERE
    tc.rnk <= 10
ORDER BY
    tc.total_return_amount DESC
