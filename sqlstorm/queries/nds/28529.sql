
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerWithAddresses AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM
        customer c
    JOIN
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
Demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        cd.cd_purchase_estimate
    FROM
        customer_demographics cd
),
AggregateData AS (
    SELECT
        cwa.c_customer_sk,
        cwa.c_first_name,
        cwa.c_last_name,
        cwa.full_address,
        cwa.ca_city,
        cwa.ca_state,
        cwa.ca_zip,
        d.cd_gender,
        d.marital_status,
        SUM(d.cd_purchase_estimate) AS total_purchase_estimate
    FROM
        CustomerWithAddresses cwa
    JOIN
        Demographics d ON cwa.c_customer_sk = d.cd_demo_sk
    GROUP BY
        cwa.c_customer_sk,
        cwa.c_first_name,
        cwa.c_last_name,
        cwa.full_address,
        cwa.ca_city,
        cwa.ca_state,
        cwa.ca_zip,
        d.cd_gender,
        d.marital_status
)
SELECT
    *,
    CASE 
        WHEN total_purchase_estimate > 50000 THEN 'High Value Customer'
        WHEN total_purchase_estimate BETWEEN 20000 AND 50000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM
    AggregateData
ORDER BY
    total_purchase_estimate DESC;
