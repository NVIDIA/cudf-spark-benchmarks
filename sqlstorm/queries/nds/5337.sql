
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CD.cd_gender,
        CD.cd_education_status,
        H.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_page_visits
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN 
        household_demographics H ON c.c_current_hdemo_sk = H.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        CD.cd_gender, 
        CD.cd_education_status, 
        H.hd_income_band_sk
),
SalesSummary AS (
    SELECT 
        total_sales,
        order_count,
        cd_gender,
        cd_education_status,
        hd_income_band_sk,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        CustomerSales
),
DemographicAnalysis AS (
    SELECT 
        sales_quartile,
        cd_gender, 
        cd_education_status,
        hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_orders
    FROM 
        SalesSummary
    GROUP BY 
        sales_quartile, 
        cd_gender, 
        cd_education_status, 
        hd_income_band_sk
)
SELECT 
    sales_quartile,
    cd_gender, 
    cd_education_status,
    hd_income_band_sk,
    customer_count,
    avg_sales,
    avg_orders
FROM 
    DemographicAnalysis
ORDER BY 
    sales_quartile, 
    customer_count DESC;
