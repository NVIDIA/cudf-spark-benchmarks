WITH concatenated_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
), address_word_count AS (
    SELECT 
        ca_address_sk,
        LENGTH(full_address) - LENGTH(REPLACE(full_address, ' ', '')) + 1 AS word_count
    FROM 
        concatenated_addresses
), demo_stats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
), address_demo_stats AS (
    SELECT 
        a.ca_address_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.word_count,
        d.customer_count,
        d.average_purchase_estimate
    FROM 
        address_word_count a
    JOIN 
        demo_stats d ON d.customer_count > 50  
)
SELECT 
    ad.cd_gender, 
    ad.cd_marital_status, 
    ad.cd_education_status, 
    AVG(ad.word_count) AS avg_word_count,
    SUM(ad.customer_count) AS total_customers,
    AVG(ad.average_purchase_estimate) AS weighted_avg_purchase_estimate
FROM 
    address_demo_stats ad
GROUP BY 
    ad.cd_gender, ad.cd_marital_status, ad.cd_education_status
ORDER BY 
    avg_word_count DESC;