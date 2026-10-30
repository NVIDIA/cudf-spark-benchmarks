
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN ib.ib_income_band_sk 
            ELSE -1 
        END AS income_band
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_statistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    ci.cd_purchase_estimate,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    CASE 
        WHEN ss.sales_rank IS NULL THEN 'No Sales'
        ELSE CONCAT('Rank ', ss.sales_rank)
    END AS sales_rank_description
FROM customer_info AS ci
LEFT JOIN sales_statistics AS ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE ci.cd_gender = 'F' 
AND ci.income_band != -1
ORDER BY total_sales DESC
LIMIT 50;
