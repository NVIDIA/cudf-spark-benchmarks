
WITH AddressedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN COALESCE(ca.ca_street_name, '') = '' THEN 'Unnamed Street'
            ELSE TRIM(LOWER(ca.ca_street_name)) 
        END AS formatted_street_name,
        CONCAT(TRIM(UPPER(ca.ca_street_number)), ' ', TRIM(LOWER(ca.ca_street_name)), ' ', TRIM(LOWER(ca.ca_street_type)), ', ', TRIM(UPPER(ca.ca_city)), ', ', TRIM(UPPER(ca.ca_state))) AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL 
        AND ca.ca_state IS NOT NULL
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
)
SELECT 
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.formatted_street_name,
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_purchase_estimate,
    d.ib_lower_bound,
    d.ib_upper_bound,
    CONCAT('Customer: ', a.c_first_name, ' ', a.c_last_name, ' | Address: ', a.full_address, ' | Demographic Info: ', 'Gender: ', d.cd_gender, ', Marital Status: ', d.cd_marital_status) AS detailed_info
FROM 
    AddressedCustomers a
JOIN 
    Demographics d ON a.c_customer_sk = d.cd_demo_sk
ORDER BY 
    a.ca_city DESC, 
    a.formatted_street_name ASC
LIMIT 100;
