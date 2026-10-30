
WITH  daily_sales AS (
    SELECT
        d.d_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_date >= '2023-01-01' AND d.d_date <= '2023-12-31'
    GROUP BY
        d.d_date_sk

    UNION ALL

    SELECT
        d.d_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM
        date_dim d
    LEFT JOIN
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE
        d.d_date >= '2023-01-01' AND d.d_date <= '2023-12-31'
    GROUP BY
        d.d_date_sk
),
sales_summary AS (
    SELECT
        d.d_year,
        SUM(ds.total_sales) AS year_total_sales,
        SUM(ds.order_count) AS year_order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ds.total_sales) DESC) AS sales_rank
    FROM
        date_dim d
    JOIN
        daily_sales ds ON d.d_date_sk = ds.d_date_sk
    GROUP BY
        d.d_year
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(hd.hd_income_band_sk) AS avg_income_band,
        SUM(CASE WHEN c.c_birth_year IS NOT NULL THEN 1 ELSE 0 END) AS known_birth_years
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY
        cd.cd_gender
)
SELECT
    ss.d_year,
    ss.year_total_sales,
    ss.year_order_count,
    cs.cd_gender,
    cs.total_customers,
    cs.avg_income_band,
    cs.known_birth_years
FROM
    sales_summary ss
FULL OUTER JOIN
    customer_summary cs ON ss.sales_rank = cs.total_customers
WHERE
    (ss.year_total_sales IS NOT NULL OR cs.total_customers IS NOT NULL)
ORDER BY
    ss.year_total_sales DESC, cs.total_customers DESC;
