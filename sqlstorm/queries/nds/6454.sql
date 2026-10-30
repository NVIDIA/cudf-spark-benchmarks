
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        CAST(d.d_date AS DATE) AS sales_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_bill_customer_sk, d.d_date
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalData AS (
    SELECT 
        sd.customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(sd.sales_date) AS last_purchase_date,
        SUM(sd.total_sales) AS total_spent,
        SUM(sd.total_orders) AS total_orders,
        SUM(sd.total_quantity) AS total_quantity,
        ib.ib_income_band_sk
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.customer_id = cd.customer_id
    LEFT JOIN 
        household_demographics hd ON cd.customer_id = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        sd.customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
)
SELECT 
    customer_id,
    cd_gender,
    cd_marital_status,
    last_purchase_date,
    total_spent,
    total_orders,
    total_quantity,
    CASE 
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalData
ORDER BY 
    total_spent DESC
LIMIT 100;
