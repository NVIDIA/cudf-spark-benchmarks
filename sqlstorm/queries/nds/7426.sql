
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
IncomeStats AS (
    SELECT 
        h.hd_income_band_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(cs.cs_sales_price) AS avg_order_value
    FROM 
        household_demographics h
    JOIN 
        catalog_sales cs ON h.hd_demo_sk = cs.cs_bill_customer_sk
    GROUP BY 
        h.hd_income_band_sk
), 
OverallStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        ci.total_sales,
        ci.total_orders,
        ci.avg_order_value,
        cs.total_orders AS customer_orders,
        cs.total_spent AS customer_spent,
        cs.avg_order_value AS customer_avg_order
    FROM 
        CustomerStats cs
    LEFT JOIN 
        IncomeStats ci ON cs.c_customer_sk = ci.hd_income_band_sk
)
SELECT 
    o.c_customer_sk,
    o.c_first_name,
    o.c_last_name,
    o.cd_gender,
    o.cd_marital_status,
    o.cd_education_status,
    COALESCE(o.total_sales, 0) AS total_sales,
    COALESCE(o.total_orders, 0) AS total_orders,
    COALESCE(o.avg_order_value, 0) AS avg_order_value,
    o.customer_orders,
    o.customer_spent,
    o.customer_avg_order
FROM 
    OverallStats o
ORDER BY 
    o.customer_spent DESC
LIMIT 100;
