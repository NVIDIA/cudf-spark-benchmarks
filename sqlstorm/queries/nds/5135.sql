
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_id,
        d.d_year AS year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2022
    GROUP BY ws_bill_cdemo_sk, d.d_year
),
customer_info AS (
    SELECT 
        cd.cd_demo_sk AS customer_demo_id,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
joined_summary AS (
    SELECT 
        ss.customer_demo_id,
        ci.gender,
        ci.marital_status,
        ci.education,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (PARTITION BY ss.year ORDER BY ss.total_sales DESC) AS sales_rank,
        ss.year 
    FROM sales_summary ss
    JOIN customer_info ci ON ss.customer_demo_id = ci.customer_demo_id
)
SELECT 
    js.customer_demo_id,
    js.gender,
    js.marital_status,
    js.education,
    js.total_sales,
    js.order_count,
    js.sales_rank
FROM joined_summary js
WHERE js.sales_rank <= 10
ORDER BY js.total_sales DESC;
