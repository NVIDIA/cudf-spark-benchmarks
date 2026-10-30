
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        (CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other' 
        END) AS gender_desc,
        COALESCE(CAST(cd.cd_purchase_estimate AS STRING), 'Unknown') AS purchase_estimate_desc
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL 
),
AggregatedData AS (
    SELECT 
        gender_desc,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        CustomerData
    GROUP BY 
        gender_desc
)
SELECT 
    gender_desc,
    customer_count,
    average_purchase_estimate,
    customer_names 
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC;
