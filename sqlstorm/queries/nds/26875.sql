
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''))) AS full_address,
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
        TRIM(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.total_return_tax, 0) AS total_return_tax,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity
FROM 
    CustomerDetails c
JOIN 
    AddressComponents a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    ReturnStats r ON c.c_customer_sk = r.sr_customer_sk
WHERE 
    a.ca_country = 'USA'
ORDER BY 
    c.full_name ASC, 
    a.ca_city;
