
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Others' 
        END AS marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') AND 
        cd.cd_purchase_estimate > 1000
),
RankedCustomers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        CustomerData
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    marital_status,
    cd_purchase_estimate,
    cd_credit_rating,
    hd_income_band_sk
FROM 
    RankedCustomers
WHERE 
    purchase_rank <= 10
ORDER BY 
    ca_state, cd_purchase_estimate DESC;
