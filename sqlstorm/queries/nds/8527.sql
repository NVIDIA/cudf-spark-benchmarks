
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN 
        CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.total_sales) AS total_sales,
        SUM(cs.order_count) AS total_orders
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = cd.ib_income_band_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.ib_lower_bound,
    ss.ib_upper_bound,
    ss.total_sales,
    ss.total_orders
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    ss.total_sales DESC;
