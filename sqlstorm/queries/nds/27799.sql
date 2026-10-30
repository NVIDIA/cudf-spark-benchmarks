
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
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
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
DateInformation AS (
    SELECT 
        d_date_sk,
        d_date,
        d_month_seq,
        d_year,
        d_day_name
    FROM 
        date_dim
),
AggregateResults AS (
    SELECT 
        a.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        COUNT(*) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        AddressParts a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        DateInformation d ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE 
        a.ca_state = 'CA'
    GROUP BY 
        a.full_address, cd.cd_gender, cd.cd_marital_status, d.d_year
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    d_year,
    total_customers,
    average_purchase_estimate,
    CONCAT('Address: ', full_address, ', Customers: ', total_customers, ', Avg Estimate: ', average_purchase_estimate) AS detailed_info
FROM 
    AggregateResults
ORDER BY 
    total_customers DESC
LIMIT 10;
