
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_location_type
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
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        ca.full_address
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ss.total_sales,
        ss.total_orders,
        CASE 
            WHEN ss.total_sales > 1000 THEN 'High Value Customer'
            WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer'
        END AS customer_value_category
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesStatistics ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_orders,
    customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_sales DESC, full_name;
