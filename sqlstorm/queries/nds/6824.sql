
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredDemographics AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name,
        rc.cd_gender, 
        rc.cd_marital_status, 
        rc.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        RankedCustomers rc
    JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rc.purchase_rank <= 10
    GROUP BY 
        rc.c_customer_sk, rc.c_first_name, rc.c_last_name, rc.cd_gender, rc.cd_marital_status, rc.cd_education_status
),
CustomerPurchases AS (
    SELECT
        cd.cd_gender,
        COUNT(*) AS total_customers,
        AVG(total_sales) AS avg_sales
    FROM 
        FilteredDemographics cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cp.cd_gender,
    cp.total_customers,
    cp.avg_sales,
    AVG(CASE 
        WHEN cd.cd_marital_status = 'M' THEN 1 
        ELSE 0 
    END) AS avg_married_percentage
FROM 
    CustomerPurchases cp
JOIN 
    FilteredDemographics cd ON cp.cd_gender = cd.cd_gender
GROUP BY 
    cp.cd_gender, cp.total_customers, cp.avg_sales
ORDER BY 
    cp.cd_gender;
