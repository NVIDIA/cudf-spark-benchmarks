
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        customer_data cd
    JOIN 
        sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    tc.sales_rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    top_customers tc
JOIN 
    customer_data cd ON tc.c_customer_sk = cd.c_customer_sk
JOIN 
    income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
