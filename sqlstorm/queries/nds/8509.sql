WITH TotalSales AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451681 
    GROUP BY 
        ws_bill_cdemo_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
CustomerAddress AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
RankedSales AS (
    SELECT 
        ts.ws_bill_cdemo_sk,
        ts.total_sales,
        ts.order_count,
        ts.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        RANK() OVER (PARTITION BY cd_gender ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
    JOIN 
        CustomerDemographics cd ON ts.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerAddress ca ON ts.ws_bill_cdemo_sk = ca.ca_address_sk
)
SELECT 
    r.sales_rank,
    r.total_sales,
    r.order_count,
    r.avg_order_value,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.ca_city,
    r.ca_state,
    r.ca_country
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.cd_gender, 
    r.total_sales DESC;