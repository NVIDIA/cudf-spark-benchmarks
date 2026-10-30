
WITH  monthly_sales AS (
    SELECT 
        ws_sold_date_sk, 
        EXTRACT(YEAR FROM d_date) AS sales_year, 
        EXTRACT(MONTH FROM d_date) AS sales_month, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM d_date), EXTRACT(MONTH FROM d_date) ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY ws_sold_date_sk, EXTRACT(YEAR FROM d_date), EXTRACT(MONTH FROM d_date)
),
customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ms.sales_year,
    ms.sales_month,
    ms.total_sales,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status
FROM monthly_sales ms
JOIN customer_rank cr ON cr.purchase_rank <= 10
WHERE ms.total_sales > (
    SELECT AVG(total_sales * 0.10) FROM monthly_sales
)
ORDER BY ms.sales_year, ms.sales_month, ms.total_sales DESC
LIMIT 100;
