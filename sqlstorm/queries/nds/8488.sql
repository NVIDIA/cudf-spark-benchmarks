
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS in_store_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id AS customer_id,
        cs.total_sales,
        cs.online_orders,
        cs.catalog_orders,
        cs.in_store_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT
    tc.customer_id,
    tc.total_sales,
    tc.online_orders,
    tc.catalog_orders,
    tc.in_store_sales
FROM
    TopCustomers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
