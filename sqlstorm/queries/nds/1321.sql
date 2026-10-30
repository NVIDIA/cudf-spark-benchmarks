
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales
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
        cd.cd_education_status
    FROM 
        customer_demographics cd 
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 10000 THEN 'Premium Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    CustomerSales cs
LEFT JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.c_customer_sk IN (SELECT h.c_customer_sk FROM HighSpenders h)
ORDER BY 
    cs.total_sales DESC;
