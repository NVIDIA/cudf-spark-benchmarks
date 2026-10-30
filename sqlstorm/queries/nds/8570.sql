
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status
FROM 
    CustomerSales cs
JOIN 
    Demographics d ON cs.c_customer_sk = d.cd_demo_sk
WHERE 
    cs.total_sales > (
        SELECT AVG(total_sales) 
        FROM CustomerSales
    )
ORDER BY 
    cs.total_sales DESC
LIMIT 10;

