
WITH sales_summary AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        w.w_warehouse_name
    FROM
        store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, dd.d_year, w.w_warehouse_name
),
ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    r.customer_id,
    r.total_sales,
    r.total_transactions,
    r.average_sales_price,
    r.cd_gender,
    r.cd_marital_status,
    r.d_year,
    r.w_warehouse_name
FROM
    ranked_sales r
WHERE
    r.sales_rank <= 10
ORDER BY
    r.w_warehouse_name, r.total_sales DESC;
