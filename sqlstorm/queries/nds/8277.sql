
WITH SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_web_site_sk, ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ss.ws_web_site_sk,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    RANK() OVER (PARTITION BY ss.ws_web_site_sk ORDER BY ss.total_sales DESC) AS sales_rank
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerDemographics cd ON ss.unique_customers = cd.customer_count
ORDER BY 
    ss.ws_web_site_sk, ss.total_sales DESC;
