
WITH concatenated_address AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', COALESCE(ca_street_number, ''), COALESCE(ca_street_name, ''), COALESCE(ca_street_type, ''), COALESCE(ca_suite_number, ''), COALESCE(ca_city, ''), COALESCE(ca_state, ''), COALESCE(ca_zip, '')) AS full_address
    FROM 
        customer_address
),
address_word_count AS (
    SELECT 
        ca_address_sk,
        LENGTH(full_address) - LENGTH(REPLACE(full_address, ' ', '')) + 1 AS word_count
    FROM 
        concatenated_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        aw.word_count
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        address_word_count aw ON c.c_current_addr_sk = aw.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    word_count,
    COUNT(*) OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY full_name) AS gender_marital_rank
FROM 
    customer_info
WHERE 
    word_count > 5
ORDER BY 
    cd_gender, cd_marital_status, full_name;
