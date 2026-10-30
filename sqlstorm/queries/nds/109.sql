
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
        id.ib_lower_bound,
        id.ib_upper_bound,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(cs.total_catalog_sales, 0) THEN 'Web'
            WHEN COALESCE(cs.total_web_sales, 0) < COALESCE(cs.total_catalog_sales, 0) THEN 'Catalog'
            ELSE 'Equal'
        END AS preferred_channel
    FROM 
        CustomerSales cs
    INNER JOIN 
        IncomeDemographics id ON cs.c_customer_sk = id.hd_demo_sk
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.ib_lower_bound,
    s.ib_upper_bound,
    s.preferred_channel
FROM 
    SalesAnalysis s
WHERE 
    s.total_web_sales + s.total_catalog_sales > 1000
    AND s.ib_upper_bound IS NOT NULL
ORDER BY 
    s.total_web_sales DESC, 
    s.total_catalog_sales DESC;
