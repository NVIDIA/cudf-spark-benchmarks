
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
        AND hd.hd_income_band_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk, 
        hd.hd_dep_count, hd.hd_vehicle_count
),
date_filter AS (
    SELECT 
        d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023
        AND d.d_moy BETWEEN 1 AND 6
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity,
    cs.total_sales,
    df.d_date_sk,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM 
    customer_summary cs
JOIN 
    web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
GROUP BY 
    cs.c_first_name, cs.c_last_name, cs.total_quantity, cs.total_sales, df.d_date_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
