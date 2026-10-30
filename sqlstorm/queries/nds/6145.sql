
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_ship_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON ws.ws_ship_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.income_band,
    COALESCE(sd.total_web_sales, 0) AS total_web_sales,
    COALESCE(sd.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(sd.total_store_sales, 0) AS total_store_sales,
    cd.web_return_count,
    cd.store_return_count
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC;
