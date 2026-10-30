
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, c.c_birth_year
),
SalesDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales_per_customer,
        SUM(cs.order_count) AS total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sd.customer_count,
    sd.avg_sales_per_customer,
    sd.total_orders
FROM 
    SalesDemographics sd
JOIN 
    customer_demographics cd ON sd.cd_demo_sk = cd.cd_demo_sk
WHERE 
    sd.customer_count > 0
ORDER BY 
    avg_sales_per_customer DESC
LIMIT 10;
