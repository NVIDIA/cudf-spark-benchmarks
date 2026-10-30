
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.c_customer_sk) AS associated_customers
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    AVG(cs.total_web_sales) AS avg_web_sales,
    SUM(cs.total_orders) AS total_orders,
    AVG(cs.avg_net_profit) AS avg_net_profit
FROM 
    CustomerDemographics cd
JOIN 
    CustomerSales cs ON cd.associated_customers = cs.c_customer_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    avg_web_sales DESC;
