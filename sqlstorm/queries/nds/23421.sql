
WITH  customer_values AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(i.ib_income_band_sk, 0) AS income_band_sk,
        COALESCE(i.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(i.ib_upper_bound, 999999999) AS income_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN 
        income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS ranking
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cv.c_customer_sk,
        CONCAT(cv.c_first_name, ' ', cv.c_last_name) AS full_name,
        cv.cd_gender,
        sd.total_sales,
        sd.order_count
    FROM 
        customer_values cv
    JOIN 
        sales_data sd ON cv.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        sd.ranking <= 10
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales' 
        WHEN tc.total_sales BETWEEN 0 AND 100 THEN 'Low Spender' 
        WHEN tc.total_sales BETWEEN 101 AND 500 THEN 'Medium Spender' 
        ELSE 'High Spender' 
    END AS spending_category,
    ROUND(AVG(COALESCE(cv.income_lower_bound, 0)) OVER (PARTITION BY tc.cd_gender), 2) AS avg_income_lower,
    AVG(COALESCE(cv.income_upper_bound, 999999999)) OVER (PARTITION BY tc.cd_gender) AS avg_income_upper
FROM 
    top_customers tc
LEFT JOIN 
    customer_values cv ON tc.c_customer_sk = cv.c_customer_sk
WHERE 
    tc.cd_gender IS NOT NULL
ORDER BY 
    tc.total_sales DESC, 
    tc.full_name ASC;
