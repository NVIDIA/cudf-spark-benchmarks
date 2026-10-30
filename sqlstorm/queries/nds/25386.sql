
WITH CustomerAddress_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        UPPER(cd_education_status) AS education_status,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.education_status,
        ca.full_address
    FROM 
        customer c
    JOIN 
        CustomerAddress_Concat ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_day_name
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
SalesSummary AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_bill_customer_sk
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.education_status,
    ci.full_address,
    ss.total_sales,
    ss.total_orders,
    di.d_year
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
JOIN 
    DateInfo di ON di.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
