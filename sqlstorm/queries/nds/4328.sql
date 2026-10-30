
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ci.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        customer ci ON ci.c_current_cdemo_sk = cd.cd_demo_sk
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        d.cd_gender,
        d.cd_marital_status,
        d.ib_lower_bound,
        d.ib_upper_bound,
        RANK() OVER (PARTITION BY d.cd_gender ORDER BY cs.total_web_sales + cs.total_catalog_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        demographic_info d ON cs.c_customer_sk = d.c_customer_sk
)
SELECT 
    r.c_customer_id,
    r.cd_gender,
    r.total_web_sales,
    r.total_catalog_sales,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top Customer'
        WHEN r.sales_rank <= 50 THEN 'Mid-Level Customer'
        ELSE 'Low Customer'
    END AS customer_status
FROM 
    ranked_sales r
WHERE 
    (r.total_web_sales > 500 OR r.total_catalog_sales > 500) 
    AND r.cd_gender IS NOT NULL
ORDER BY 
    r.cd_gender, r.sales_rank;
