
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year
    FROM 
        date_dim
    WHERE 
        d_year BETWEEN 2020 AND 2023
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedResults AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.order_count, 0) AS order_count,
        COALESCE(s.total_quantity, 0) AS total_quantity
    FROM 
        CustomerDetails c
    LEFT JOIN SalesSummary s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    total_quantity
FROM 
    CombinedResults
ORDER BY 
    total_sales DESC,
    order_count DESC
LIMIT 100;
