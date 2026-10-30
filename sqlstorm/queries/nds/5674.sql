
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_bill_customer_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Has Income Band'
            ELSE 'No Income Band'
        END AS income_band,
        COALESCE(cd.cd_dep_count, 0) AS dependents_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), ranked_sales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.income_band,
        si.total_sales,
        si.total_profit,
        si.order_count,
        RANK() OVER (ORDER BY si.total_profit DESC) AS profit_rank
    FROM customer_info ci
    JOIN sales_data si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.income_band,
    r.total_sales,
    r.total_profit,
    r.order_count,
    r.profit_rank
FROM ranked_sales r
WHERE r.order_count > 10
ORDER BY r.profit_rank
LIMIT 10;
