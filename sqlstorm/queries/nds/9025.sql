
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE 
            WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_paid 
            ELSE 0 
        END) AS total_web_sales,
        SUM(CASE 
            WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_net_paid 
            ELSE 0 
        END) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesStats AS (
    SELECT 
        c.c_customer_sk,
        total_web_sales,
        total_store_sales,
        web_orders,
        store_orders,
        total_web_sales + total_store_sales AS total_sales
    FROM 
        CustomerSales
    JOIN customer c ON c.c_customer_sk = CustomerSales.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ib.ib_income_band_sk,
    COUNT(*) AS customer_count,
    AVG(ss.total_sales) AS avg_total_sales,
    SUM(ss.web_orders) AS total_web_orders,
    SUM(ss.store_orders) AS total_store_orders
FROM 
    SalesStats ss
JOIN 
    Demographics ds ON ss.c_customer_sk = ds.cd_demo_sk
JOIN 
    income_band ib ON ds.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ib.ib_income_band_sk
ORDER BY 
    ds.cd_gender, ds.cd_marital_status, ds.cd_education_status, ib.ib_income_band_sk;
