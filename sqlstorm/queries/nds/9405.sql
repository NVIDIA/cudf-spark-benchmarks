
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
), Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), SalesWithDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        Demographics d ON cs.c_customer_sk = d.c_customer_sk
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    AVG(sd.total_sales) AS avg_sales,
    AVG(sd.order_count) AS avg_order_count,
    COUNT(*) AS customer_count
FROM 
    SalesWithDemographics sd
WHERE 
    sd.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
GROUP BY 
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status
ORDER BY 
    avg_sales DESC;
