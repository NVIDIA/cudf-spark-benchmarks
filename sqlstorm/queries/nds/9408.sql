
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.average_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM
        CustomerSales cs
)
SELECT
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.average_order_value,
    d.d_date_id
FROM
    TopCustomers tc
JOIN
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN
    date_dim d ON DATE_PART('year', d.d_date) = 2023
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_sales DESC;
