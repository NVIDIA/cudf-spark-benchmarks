
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 1010
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        rs.ws_bill_customer_sk,
        rs.total_sales,
        rs.order_count,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.hd_income_band_sk
    FROM 
        RankedSales rs
    JOIN 
        Demographics d ON rs.ws_bill_customer_sk = d.c_customer_sk
)
SELECT 
    sd.hd_income_band_sk,
    sd.cd_gender,
    sd.cd_marital_status,
    AVG(sd.total_sales) AS avg_sales,
    COUNT(sd.ws_bill_customer_sk) AS customer_count,
    SUM(sd.order_count) AS total_orders
FROM 
    SalesWithDemographics sd
GROUP BY 
    sd.hd_income_band_sk, sd.cd_gender, sd.cd_marital_status
ORDER BY 
    avg_sales DESC
LIMIT 10;
