
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregatedDetails AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        sd.total_sales,
        sd.total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    AggregatedDetails
WHERE 
    ca_state = 'CA' AND 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
