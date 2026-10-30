
WITH RankedSales AS (
    SELECT
        s.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        s.s_store_id
),
TopStores AS (
    SELECT
        *,
        (SELECT SUM(total_sales_amount) FROM RankedSales) AS total_sales_all_stores
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
)
SELECT
    ts.s_store_id,
    ts.total_sales,
    ts.total_sales_amount,
    ts.total_discount,
    ROUND((ts.total_sales_amount / ts.total_sales_all_stores) * 100, 2) AS sales_percentage_of_total
FROM
    TopStores ts
ORDER BY
    ts.total_sales_amount DESC;
