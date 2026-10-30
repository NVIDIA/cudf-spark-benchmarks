
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        ROW_NUMBER() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
IncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_demo_sk, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.sales_rank,
    id.ib_lower_bound,
    id.ib_upper_bound,
    id.household_count
FROM 
    RankedSales r
JOIN 
    CustomerSales cs ON r.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    IncomeDemographics id ON cs.c_customer_sk = id.hd_demo_sk
WHERE 
    (r.total_web_sales > 5000 OR r.total_catalog_sales > 10000)
    AND (id.ib_lower_bound IS NOT NULL OR id.ib_upper_bound IS NULL)
ORDER BY 
    r.sales_rank
LIMIT 100;
