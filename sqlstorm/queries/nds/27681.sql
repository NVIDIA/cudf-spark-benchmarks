
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        dt.d_date AS birth_date,
        dt.d_year AS birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dt ON c.c_birth_day = dt.d_dom AND c.c_birth_month = dt.d_moy AND c.c_birth_year = dt.d_year
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ap.full_address,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressParts ap ON ci.c_customer_sk = ap.ca_address_sk
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    total_sales,
    total_orders
FROM 
    FinalReport
ORDER BY 
    total_sales DESC
LIMIT 100;
