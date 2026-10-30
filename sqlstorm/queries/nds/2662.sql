
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_count
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.income_band_sk,
    ci.hd_buy_potential,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No sales'
        WHEN ss.total_sales > 1000 THEN 'High spender'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium spender'
        ELSE 'Low spender'
    END AS spending_category,
    CASE 
        WHEN ci.page_count IS NULL THEN 'No pages'
        WHEN ci.page_count > 5 THEN 'Frequent browser'
        ELSE 'Occasional visitor'
    END AS browsing_behavior
FROM 
    customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_purchase_estimate > 500
ORDER BY 
    total_sales DESC, 
    full_name;
