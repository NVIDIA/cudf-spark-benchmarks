
WITH string_benchmark AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_county) AS lower_county,
        REPLACE(ca_state, 'CA', 'California') AS state_replacement
    FROM 
        customer_address
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sb.full_address,
        sb.address_length,
        sb.upper_city,
        sb.lower_county,
        sb.state_replacement
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        string_benchmark sb ON c.c_current_addr_sk = sb.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    address_length,
    upper_city,
    lower_county,
    state_replacement
FROM 
    customer_analysis
WHERE 
    cd_gender = 'F' 
    AND cd_marital_status = 'M' 
    AND address_length > 50
ORDER BY 
    address_length DESC
LIMIT 100;
