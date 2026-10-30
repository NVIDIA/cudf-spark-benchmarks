WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450122 AND 2450457  
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales,
        SUM(order_count) AS total_orders,
        AVG(total_sales) AS avg_total_sales,
        AVG(order_count) AS avg_orders_per_customer
    FROM 
        customer_sales
    GROUP BY 
        cd_gender, cd_marital_status, ib_income_band_sk
)
SELECT 
    gender_summary.cd_gender,
    gender_summary.cd_marital_status,
    income_band.ib_lower_bound,
    income_band.ib_upper_bound,
    gender_summary.customer_count,
    gender_summary.total_sales,
    gender_summary.total_orders,
    gender_summary.avg_total_sales,
    gender_summary.avg_orders_per_customer
FROM 
    sales_summary gender_summary
JOIN 
    income_band ON gender_summary.ib_income_band_sk = income_band.ib_income_band_sk
ORDER BY 
    gender_summary.cd_gender, gender_summary.cd_marital_status, income_band.ib_lower_bound;