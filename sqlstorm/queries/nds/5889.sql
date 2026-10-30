
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, cs.cs_net_paid, ss.ss_net_paid, 0)) AS total_net_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_net_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_sales,
    d.d_year,
    SUM(ws.ws_quantity) AS total_items_purchased
FROM
    TopCustomers tc
JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    tc.sales_rank <= 10
GROUP BY
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_net_sales, d.d_year
ORDER BY
    tc.total_net_sales DESC, d.d_year DESC;
