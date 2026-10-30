
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count
    FROM
        CustomerSales cs
    WHERE
        cs.sales_rank <= 10
),
StoreSales AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM
        store_sales ss
    JOIN
        TopCustomers tc ON ss.ss_customer_sk = tc.c_customer_sk
    GROUP BY
        ss.ss_store_sk
),
OverallSales AS (
    SELECT
        SUM(total_sales) AS total_sales_all,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM
        CustomerSales
)
SELECT
    s.s_store_name,
    ss.total_store_sales,
    os.total_sales_all,
    os.unique_customers
FROM
    store s
JOIN
    StoreSales ss ON s.s_store_sk = ss.ss_store_sk
CROSS JOIN
    OverallSales os
ORDER BY
    ss.total_store_sales DESC;
