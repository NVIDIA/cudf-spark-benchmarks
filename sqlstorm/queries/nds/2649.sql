
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS total_items_ordered
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
    FROM
        CustomerSales
),
HighValueReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM
        catalog_returns
    WHERE
        cr_return_quantity > 0
    GROUP BY
        cr_returning_customer_sk
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_paid,
    tc.total_orders,
    COALESCE(hvr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(hvr.total_returns, 0) AS total_returns,
    CASE
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM
    TopCustomers tc
LEFT JOIN
    HighValueReturns hvr ON tc.c_customer_sk = hvr.cr_returning_customer_sk
WHERE
    tc.total_net_paid > 1000
ORDER BY
    tc.total_net_paid DESC;
