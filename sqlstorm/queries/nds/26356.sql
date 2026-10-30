
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LOWER(ca_street_name) AS lower_street_name
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
GroupedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        dem.cd_gender,
        dem.cd_marital_status,
        COUNT(*) AS num_orders
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        CustomerDemographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip, ad.ca_country, dem.cd_gender, dem.cd_marital_status
),
TopAddresses AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        COUNT(*) AS order_count
    FROM 
        GroupedCustomers
    WHERE 
        num_orders > 0
    GROUP BY 
        full_address, ca_city, ca_state, ca_zip, ca_country
    ORDER BY 
        order_count DESC
    LIMIT 10
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY order_count DESC) AS rank,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    order_count
FROM 
    TopAddresses;
