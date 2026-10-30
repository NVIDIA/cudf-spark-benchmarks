
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.c_customer_sk) AS num_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesSummary AS (
    SELECT
        c.cd_gender AS gender,
        c.cd_marital_status AS marital_status,
        c.cd_education_status AS education_status,
        SUM(cs.total_web_sales) AS total_sales,
        SUM(cs.total_orders) AS total_orders,
        AVG(cs.avg_net_profit) AS avg_net_profit
    FROM 
        CustomerDemographics c
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = c.cd_demo_sk
    GROUP BY 
        c.cd_gender, c.cd_marital_status, c.cd_education_status
)
SELECT 
    gender,
    marital_status,
    education_status,
    total_sales,
    total_orders,
    avg_net_profit
FROM 
    SalesSummary
ORDER BY 
    total_sales DESC
LIMIT 10;
