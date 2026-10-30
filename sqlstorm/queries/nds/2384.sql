
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cb3.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics cb3 ON cd.cd_demo_sk = cb3.hd_demo_sk
    LEFT JOIN 
        income_band ib ON cb3.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.total_web_sales,
    hsc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound
FROM 
    HighSpendingCustomers hsc
LEFT JOIN 
    CustomerDemographics cd ON hsc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender IS NOT NULL AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
ORDER BY 
    hsc.total_web_sales DESC;
