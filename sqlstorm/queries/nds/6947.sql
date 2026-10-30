
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesWithDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    swd.cd_gender,
    swd.cd_marital_status,
    swd.cd_education_status,
    COUNT(swd.c_customer_sk) AS customer_count,
    AVG(swd.total_sales) AS average_sales,
    SUM(swd.order_count) AS total_orders
FROM SalesWithDemographics swd
WHERE swd.total_sales > 1000
GROUP BY 
    swd.cd_gender,
    swd.cd_marital_status,
    swd.cd_education_status
ORDER BY average_sales DESC;
