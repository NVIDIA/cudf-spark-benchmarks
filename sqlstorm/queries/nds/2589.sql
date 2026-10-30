WITH customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
        cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count
),
seasonal_sales AS (
    SELECT
        EXTRACT(YEAR FROM dd.d_date) AS sale_year,
        EXTRACT(MONTH FROM dd.d_date) AS sale_month,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM
        date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        sale_year, sale_month
),
ranked_sales AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        RANK() OVER (PARTITION BY cs.cd_marital_status ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        customer_summary cs
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.total_sales,
    COALESCE(r.sales_rank, 0) AS sales_rank,
    ss.sale_year,
    ss.sale_month,
    ss.monthly_sales,
    CASE
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM
    customer_summary cs
LEFT JOIN ranked_sales r ON cs.c_customer_sk = r.c_customer_sk
LEFT JOIN seasonal_sales ss ON EXTRACT(YEAR FROM cast('2002-10-01' as date)) = ss.sale_year
WHERE
    cs.cd_gender = 'F' AND cs.total_sales IS NOT NULL
ORDER BY
    cs.total_sales DESC,
    cs.c_last_name;