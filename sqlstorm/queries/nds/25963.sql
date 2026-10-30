
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ss.total_sales,
        ss.total_orders
    FROM 
        CustomerInfo ci
    JOIN 
        AddressDetails a ON ci.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name, 
    full_address, 
    ca_city, 
    ca_state, 
    ca_country, 
    COALESCE(total_sales, 0) AS total_sales, 
    COALESCE(total_orders, 0) AS total_orders 
FROM 
    FinalReport
ORDER BY 
    total_sales DESC, 
    full_name;
