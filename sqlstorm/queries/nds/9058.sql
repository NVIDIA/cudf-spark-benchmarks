
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy BETWEEN 6 AND 8
        )
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)

SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT AVG(total_sales) FROM CustomerSales) AS avg_sales,
    (SELECT AVG(order_count) FROM CustomerSales) AS avg_orders
FROM
    TopCustomers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
