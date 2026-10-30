
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), SalesByDemographics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.demographic_count
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.cd_gender = cd.cd_gender 
        AND cs.cd_marital_status = cd.cd_marital_status 
        AND cs.cd_education_status = cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT cs.c_customer_id) AS num_customers,
    AVG(cs.total_sales) AS avg_sales,
    AVG(cs.total_orders) AS avg_orders,
    SUM(cs.total_orders) AS total_orders_by_demographic
FROM 
    SalesByDemographics cs
JOIN 
    CustomerDemographics cd ON cs.cd_gender = cd.cd_gender 
    AND cs.cd_marital_status = cd.cd_marital_status 
    AND cs.cd_education_status = cd.cd_education_status
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    avg_sales DESC, num_customers DESC
LIMIT 10;
