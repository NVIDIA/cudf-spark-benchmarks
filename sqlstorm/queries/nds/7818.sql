
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
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
demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
sales_summary AS (
    SELECT 
        d.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.hd_income_band_sk,
        d.hd_buy_potential,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales
    FROM 
        demographics d
    LEFT JOIN 
        customer_sales cs ON d.c_customer_sk = cs.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk,
    SUM(ss.total_sales) AS total_sales_by_category
FROM 
    sales_summary ss
JOIN 
    income_band ib ON ss.hd_income_band_sk = ib.ib_income_band_sk
JOIN 
    customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    ib.ib_income_band_sk
ORDER BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    ib.ib_income_band_sk;
