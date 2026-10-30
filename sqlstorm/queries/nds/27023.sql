
WITH AddressDetails AS (
    SELECT 
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
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date,
        d_day_name,
        d_month_seq,
        d_year,
        d_date_sk
    FROM 
        date_dim
),
Returns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    cu.full_name,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_education_status,
    cu.cd_purchase_estimate,
    d.d_date,
    d.d_day_name,
    d.d_month_seq,
    d.d_year,
    r.total_returned,
    r.total_return_amt
FROM 
    AddressDetails ca
JOIN 
    CustomerDetails cu ON cu.cd_purchase_estimate > 10000
JOIN 
    DateDetails d ON d.d_year = 2023
JOIN 
    Returns r ON r.sr_returned_date_sk = d.d_date_sk
ORDER BY 
    r.total_return_amt DESC, 
    ca.ca_city;
