
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_sales cs ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.total_web_sales) AS total_web_sales,
    SUM(cs.total_catalog_sales) AS total_catalog_sales,
    SUM(cs.total_web_orders) AS total_web_orders,
    SUM(cs.total_catalog_orders) AS total_catalog_orders,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
FROM 
    customer_sales cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
JOIN 
    income_band ib ON ib.ib_income_band_sk = cd.ib_income_band_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    total_web_sales DESC, demographic_count DESC
LIMIT 10;
