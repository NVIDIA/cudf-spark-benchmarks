
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_paid,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
    FROM
        CustomerSales cs
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_net_paid, 0) AS total_net_paid,
    tc.order_count,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT COUNT(DISTINCT ws.ws_order_number)
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS total_orders_from_weblinks
FROM
    TopCustomers tc
WHERE
    tc.sales_rank <= 10 OR tc.order_count > 5
ORDER BY
    total_net_paid DESC;
