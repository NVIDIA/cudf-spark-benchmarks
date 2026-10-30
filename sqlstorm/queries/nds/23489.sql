
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS dep_employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS dep_college_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales)
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(sr.total_returned, 0) AS total_returned,
    COALESCE(sd.total_net_paid, 0) AS total_net_paid,
    sd.total_orders,
    sd.total_quantity
FROM 
    CustomerDemographics cd
LEFT JOIN 
    RankedReturns sr ON cd.c_customer_sk = sr.sr_customer_sk AND sr.return_rank = 1
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.customer_sk
WHERE 
    cd.purchase_estimate > 1000
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status IS NULL)
ORDER BY 
    total_returned DESC, total_net_paid DESC
LIMIT 10;
