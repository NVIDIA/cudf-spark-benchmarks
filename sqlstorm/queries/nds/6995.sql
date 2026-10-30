
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ib.ib_income_band_sk AS income_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalData AS (
    SELECT 
        c.customer_id,
        c.gender,
        c.marital_status,
        c.income_band,
        s.total_sales,
        s.total_orders,
        s.avg_order_value
    FROM 
        CustomerDemographics c
    JOIN 
        SalesData s ON c.customer_id = s.customer_id
)
SELECT 
    gender,
    marital_status,
    income_band,
    COUNT(customer_id) AS customer_count,
    SUM(total_sales) AS total_sales,
    AVG(avg_order_value) AS avg_order_value
FROM 
    FinalData
GROUP BY 
    gender, marital_status, income_band
ORDER BY 
    total_sales DESC;
