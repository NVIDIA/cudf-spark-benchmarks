
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
EligibleCustomers AS (
    SELECT 
        rc.* 
    FROM 
        RankedCustomers rc 
    WHERE 
        rc.rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM EligibleCustomers)
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ec.full_name,
        ec.cd_gender,
        ec.cd_marital_status,
        ec.cd_education_status,
        sd.total_sales
    FROM 
        EligibleCustomers ec
    LEFT JOIN 
        SalesData sd ON ec.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.gender,
    cd.marital_status,
    COUNT(*) AS customer_count,
    AVG(cs.total_sales) AS avg_sales,
    SUM(cs.total_sales) AS total_sales
FROM 
    CustomerSales cs
JOIN 
    (SELECT DISTINCT cd_gender AS gender, cd_marital_status AS marital_status FROM customer_demographics) cd
ON 
    cs.cd_gender = cd.gender AND cs.cd_marital_status = cd.marital_status
GROUP BY 
    cd.gender, cd.marital_status
ORDER BY 
    cd.gender, cd.marital_status;
