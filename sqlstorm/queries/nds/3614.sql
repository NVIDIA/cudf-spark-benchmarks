
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
),
HighValueCustomers AS (
    SELECT
        *
    FROM
        SalesRanked
    WHERE
        sales_rank <= 10
),
StoreSalesSummary AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM
        store_sales ss
    GROUP BY
        ss.ss_store_sk
)
SELECT
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(s.total_store_sales, 0) AS store_sales,
    hvc.total_sales AS online_sales,
    (COALESCE(s.total_store_sales, 0) + hvc.total_sales) AS total_combined_sales
FROM
    HighValueCustomers hvc
LEFT JOIN
    StoreSalesSummary s ON hvc.c_customer_sk = s.ss_store_sk
ORDER BY
    total_combined_sales DESC;
