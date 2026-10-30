WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(ca_city) AS city_lower,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        hd_income_band_sk,
        hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        ad.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON ad.ca_address_id = cd.c_customer_id  
    WHERE 
        cd.cd_purchase_estimate > 50000
        AND ad.ca_state = 'CA'  
),
Report AS (
    SELECT 
        hvc.full_name,
        hvc.full_address,
        hvc.cd_gender,
        hvc.cd_marital_status,
        COUNT(*) OVER (PARTITION BY hvc.cd_gender) AS gender_count,
        COUNT(*) OVER (PARTITION BY hvc.cd_marital_status) AS marital_status_count,
        COUNT(*) OVER () AS total_count
    FROM 
        HighValueCustomers hvc
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    gender_count,
    marital_status_count,
    total_count,
    CONCAT('This is a ', cd_marital_status, ' ', cd_gender, ' customer.') AS customer_description
FROM 
    Report
ORDER BY 
    cd_gender DESC, 
    cd_marital_status;