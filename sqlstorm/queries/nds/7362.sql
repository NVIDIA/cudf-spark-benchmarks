
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_sales,
        r.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    sd.cd_gender,
    AVG(sd.total_sales) AS avg_sales,
    SUM(sd.order_count) AS total_orders,
    COUNT(DISTINCT sd.ws_bill_customer_sk) AS customer_count
FROM 
    SalesWithDemographics sd
GROUP BY 
    sd.cd_gender
ORDER BY 
    avg_sales DESC;
