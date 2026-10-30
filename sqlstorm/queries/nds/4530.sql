
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(is_high_value_customer.is_high_value, 'No') AS high_value_customer,
    income_summary.customer_count,
    income_summary.average_purchase_estimate
FROM 
    customer_sales cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) > 1000 THEN 'Yes' 
            ELSE 'No' 
        END AS is_high_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
) is_high_value_customer ON cs.c_customer_sk = is_high_value_customer.c_customer_sk
JOIN 
    income_summary ON cd.cd_demo_sk = income_summary.hd_income_band_sk
ORDER BY 
    cs.total_web_sales DESC, cs.total_catalog_sales DESC, cs.total_store_sales DESC
LIMIT 100;
