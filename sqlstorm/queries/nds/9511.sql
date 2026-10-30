
WITH SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesOverview AS (
    SELECT 
        sd.d_year,
        sd.total_sales,
        sd.order_count,
        sd.unique_customers,
        cd.avg_purchase_estimate,
        cd.demographic_count
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.total_sales > 1000000
)
SELECT 
    soo.d_year,
    soo.total_sales,
    soo.order_count,
    soo.unique_customers,
    COALESCE(soo.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    COALESCE(soo.demographic_count, 0) AS demographic_count
FROM 
    SalesOverview soo
ORDER BY 
    soo.d_year;
