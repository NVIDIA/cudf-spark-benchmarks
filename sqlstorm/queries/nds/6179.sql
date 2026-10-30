
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
HighValueCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerSales 
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), 
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_sales,
        hvc.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        HighValueCustomers hvc
    JOIN 
        CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    f.c_customer_sk, 
    f.total_sales, 
    f.total_orders, 
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.cd_dep_count
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC 
LIMIT 10;
