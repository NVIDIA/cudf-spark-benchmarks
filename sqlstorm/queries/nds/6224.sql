
WITH recent_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 12)
    GROUP BY 
        ws_bill_customer_sk
),
demographics AS (
    SELECT 
        c.c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_ranked AS (
    SELECT 
        r.ws_bill_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_dep_count,
        d.ib_lower_bound,
        d.ib_upper_bound,
        r.total_sales,
        r.order_count,
        RANK() OVER (PARTITION BY d.cd_gender ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        recent_sales r
    JOIN 
        demographics d ON r.ws_bill_customer_sk = d.c_customer_sk
)
SELECT 
    d.cd_gender,
    AVG(r.total_sales) AS avg_total_sales,
    AVG(r.order_count) AS avg_order_count,
    COUNT(CASE WHEN sales_rank <= 10 THEN 1 END) AS top_10_customers_count
FROM 
    sales_ranked r
JOIN 
    demographics d ON r.ws_bill_customer_sk = d.c_customer_sk
GROUP BY 
    d.cd_gender
ORDER BY 
    d.cd_gender;
