
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        h.hd_income_band_sk,
        d.d_year
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
),
top_customers AS (
    SELECT
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.hd_income_band_sk,
        ss.total_sales,
        ss.total_orders
    FROM
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    tc.*,
    CONCAT('Income Band: ', ib.ib_lower_bound, '-', ib.ib_upper_bound) AS income_band_range
FROM 
    top_customers tc
LEFT JOIN 
    income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    (tc.cd_gender = 'F' OR tc.cd_marital_status = 'S')
ORDER BY 
    tc.total_sales DESC
LIMIT 20;
