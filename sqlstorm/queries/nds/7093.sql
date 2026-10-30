
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
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
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000
),
SalesByDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        CustomerSales cs
    JOIN 
        Demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    sbd.cd_gender,
    sbd.cd_marital_status,
    COUNT(sbd.c_customer_sk) AS customer_count,
    AVG(sbd.total_sales) AS avg_sales,
    SUM(sbd.total_sales) AS total_sales
FROM 
    SalesByDemographics sbd
GROUP BY 
    sbd.cd_gender, sbd.cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 10;
