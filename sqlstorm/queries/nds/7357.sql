
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        CAST(d.d_date AS DATE) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws_bill_customer_sk, CAST(d.d_date AS DATE)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
join_summary AS (
    SELECT 
        ss.sales_date,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.hd_income_band_sk,
        ss.total_orders,
        ss.total_quantity,
        ss.total_revenue
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ss.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    js.sales_date,
    js.c_customer_sk,
    js.c_first_name,
    js.c_last_name,
    js.cd_gender,
    js.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    js.total_orders,
    js.total_quantity,
    js.total_revenue
FROM 
    join_summary js
LEFT JOIN 
    income_band ib ON js.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    js.total_revenue > 1000
ORDER BY 
    js.sales_date, js.total_revenue DESC
LIMIT 100;
