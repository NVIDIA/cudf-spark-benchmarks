
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales, 
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 10000
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM 
        HighValueCustomers hvc
    JOIN 
        customer c ON hvc.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_income_band,
    COUNT(hvc.c_customer_id) AS total_high_value_customers
FROM 
    CustomerDemographics cd
JOIN 
    HighValueCustomers hvc ON cd.cd_gender = hvc.c_customer_id
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.avg_income_band
ORDER BY 
    total_high_value_customers DESC;
