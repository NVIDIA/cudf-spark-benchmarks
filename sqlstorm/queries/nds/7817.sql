
WITH sales_summary AS (
    SELECT
        c.c_birth_month,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    JOIN customer c ON c.c_customer_sk = ws_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = ws_sold_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_birth_month
),
demographics_summary AS (
    SELECT
        cd_education_status,
        COUNT(distinct c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_education_status
)
SELECT
    s.c_birth_month,
    s.total_sales,
    s.total_profit,
    s.order_count,
    d.cd_education_status,
    d.customer_count,
    d.avg_purchase_estimate
FROM
    sales_summary s
JOIN demographics_summary d ON s.c_birth_month = d.customer_count
ORDER BY
    s.total_sales DESC,
    d.customer_count DESC
LIMIT 100;
