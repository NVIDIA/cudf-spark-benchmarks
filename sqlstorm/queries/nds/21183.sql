
WITH  income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IS NOT NULL
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium'
            ELSE 'High'
        END as purchase_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) as total_sales,
        COUNT(ws.ws_order_number) as total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
joined_info AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.purchase_category,
        COALESCE(ss.total_sales, 0) as total_sales,
        COALESCE(ss.total_orders, 0) as total_orders,
        CASE 
            WHEN ss.total_sales = 0 THEN 'No Sales'
            WHEN ss.total_sales < 1000 THEN 'Low Sales'
            ELSE 'High Sales'
        END as sales_status
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ji.c_customer_sk,
    ji.c_first_name,
    ji.c_last_name,
    ji.cd_gender,
    ji.cd_marital_status,
    ji.purchase_category,
    ji.total_sales,
    ji.total_orders,
    ji.sales_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE 
        WHEN ji.total_sales < ib.ib_lower_bound THEN 'Below Income Band'
        WHEN ji.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 'Within Income Band'
        ELSE 'Above Income Band'
    END income_band_status
FROM joined_info ji
LEFT JOIN income_bracket ib ON ji.total_sales >= ib.ib_lower_bound
ORDER BY ji.total_sales DESC, ji.c_last_name, ji.c_first_name;
