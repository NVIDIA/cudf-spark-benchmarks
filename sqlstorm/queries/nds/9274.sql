
WITH sales_summary AS (
    SELECT
        d.d_year,
        s.s_store_id,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        AVG(ss_sales_price) AS average_sales_price
    FROM
        date_dim d
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        d.d_year BETWEEN 2018 AND 2020
    GROUP BY
        d.d_year,
        s.s_store_id
),
demographics_summary AS (
    SELECT
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_gender
),
final_summary AS (
    SELECT 
        ss.d_year,
        ss.s_store_id,
        ss.total_sales,
        ss.total_transactions,
        ss.average_sales_price,
        ds.cd_gender,
        ds.customer_count,
        ds.avg_purchase_estimate
    FROM 
        sales_summary ss
    JOIN demographics_summary ds ON ds.customer_count > 100
)
SELECT
    fs.d_year,
    fs.s_store_id,
    fs.total_sales,
    fs.total_transactions,
    fs.average_sales_price,
    fs.cd_gender,
    fs.customer_count,
    fs.avg_purchase_estimate
FROM
    final_summary fs
ORDER BY
    fs.d_year DESC,
    fs.total_sales DESC;
