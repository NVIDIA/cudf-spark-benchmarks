
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_ext_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ext_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_amount,
        COUNT(*) AS total_orders
    FROM ranked_sales
    GROUP BY ws_bill_customer_sk
),
customer_demographics_with_income AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents' 
            ELSE 'Has Dependents' 
        END AS dep_status,
        td.total_amount,
        td.total_orders
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN total_sales td ON c.c_customer_sk = td.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        income_band, 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(total_amount) AS avg_total_amount
    FROM customer_demographics_with_income
    WHERE total_amount IS NOT NULL
    AND (total_orders > 5 OR dep_status = 'Has Dependents')
    GROUP BY income_band, cd_gender
)
SELECT 
    hi.income_band,
    hi.cd_gender,
    COALESCE(hi.customer_count, 0) AS customer_count,
    COALESCE(hi.avg_total_amount, 0) AS avg_total_amount,
    CASE 
        WHEN hi.customer_count > 100 THEN 'High Engagement'
        WHEN hi.customer_count BETWEEN 50 AND 100 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM high_value_customers hi
FULL OUTER JOIN income_band ib ON hi.income_band = ib.ib_income_band_sk
WHERE 
    hi.cd_gender = 'M' OR hi.cd_gender = 'F'
ORDER BY hi.income_band, hi.cd_gender;
