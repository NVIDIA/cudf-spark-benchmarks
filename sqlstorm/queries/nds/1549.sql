
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_ext_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_ext_sales_price ELSE 0 END) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        DENSE_RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        customer_sales cs
),
income_levels AS (
    SELECT 
        hd.hd_demo_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 'Income Band ' || ib.ib_income_band_sk 
            ELSE 'Unknown Income Band' 
        END AS income_band
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ss.c_customer_sk,
    ss.total_sales,
    ss.sales_rank,
    il.income_band
FROM 
    sales_summary ss
LEFT JOIN 
    customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    income_levels il ON cd.cd_demo_sk = il.hd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND total_sales > 1000) OR 
    (cd.cd_marital_status = 'M' AND total_sales > 1500)
ORDER BY 
    ss.sales_rank ASC,
    ss.total_sales DESC
LIMIT 50;
