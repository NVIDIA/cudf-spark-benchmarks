
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
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
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk, 
        i.ib_lower_bound, 
        i.ib_upper_bound, 
        COUNT(DISTINCT cd.cd_demo_sk) AS demographics_count
    FROM 
        household_demographics h
    INNER JOIN 
        income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    INNER JOIN 
        customer_demographics cd ON h.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        h.hd_demo_sk, i.ib_lower_bound, i.ib_upper_bound
)
SELECT 
    cds.c_customer_sk,
    cds.total_web_sales,
    cds.total_catalog_sales,
    cds.total_store_sales,
    id.ib_lower_bound,
    id.ib_upper_bound,
    id.demographics_count
FROM 
    CustomerSales cds
JOIN 
    IncomeDemographics id ON cds.c_customer_sk = id.hd_demo_sk
WHERE 
    cds.total_web_sales > 50000
ORDER BY 
    cds.total_web_sales DESC, id.demographics_count DESC;
