
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_month IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound,
    CASE 
        WHEN hvc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_tier
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    (cd.cd_gender = 'M' AND hvc.total_sales > 5000) OR 
    (cd.cd_gender = 'F' AND hvc.total_sales > 3000)
ORDER BY 
    hvc.total_sales DESC
LIMIT 20;
