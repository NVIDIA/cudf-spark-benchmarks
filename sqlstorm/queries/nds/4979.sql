
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer AS c
        LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
), StoreSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM
        customer AS c
        LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk > (
            SELECT MAX(d.d_date_sk)
            FROM date_dim AS d
            WHERE d.d_year = 2020
        )
    GROUP BY
        c.c_customer_sk
), SalesComparison AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) - COALESCE(ss.total_store_sales, 0)) AS profit_difference
    FROM
        CustomerSales AS cs
        FULL OUTER JOIN StoreSales AS ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT
    sc.c_customer_sk,
    sc.c_first_name,
    sc.c_last_name,
    sc.total_web_sales,
    sc.total_store_sales,
    sc.profit_difference,
    CASE
        WHEN sc.profit_difference > 0 THEN 'Profitable'
        WHEN sc.profit_difference < 0 THEN 'Loss'
        ELSE 'Break-even'
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY sc.profit_difference DESC) AS sales_rank
FROM
    SalesComparison AS sc
WHERE
    sc.total_web_sales > 1000 OR sc.total_store_sales > 1000
ORDER BY
    sales_rank;
