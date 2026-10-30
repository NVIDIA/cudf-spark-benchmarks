
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.hd_income_band_sk
    FROM 
        customer_summary cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 50000
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_sales,
    hvc.total_orders,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    high_value_customers hvc
JOIN 
    income_band ib ON hvc.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    hvc.total_sales DESC
LIMIT 50;
