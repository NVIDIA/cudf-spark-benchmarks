WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd 
    ON 
        c.c_current_cdemo_sk = cd.cd_demo_sk
),
WebSalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedDetails AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        COALESCE(ws.total_quantity, 0) AS total_quantity,
        COALESCE(ws.total_net_paid, 0) AS total_net_paid
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad 
    ON 
        ad.ca_address_sk = cd.c_customer_sk      
    LEFT JOIN 
        WebSalesDetails ws 
    ON 
        ws.ws_bill_customer_sk = cd.c_customer_sk
),
FinalResults AS (
    SELECT 
        full_name,
        cd_gender,
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        total_quantity,
        total_net_paid,
        CASE 
            WHEN total_net_paid >= 1000 THEN 'High Value'
            WHEN total_net_paid BETWEEN 500 AND 999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CombinedDetails
)
SELECT 
    ca_city,
    COUNT(*) AS customer_count,
    AVG(total_quantity) AS average_quantity,
    SUM(total_net_paid) AS total_sales,
    customer_value_category
FROM 
    FinalResults
GROUP BY 
    ca_city, customer_value_category
ORDER BY 
    ca_city, customer_value_category;