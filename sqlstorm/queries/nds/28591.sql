WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank_by_estimate <= 5
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS distinct_address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
FinalReport AS (
    SELECT 
        tc.full_name,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_education_status,
        tc.cd_purchase_estimate,
        ac.distinct_address_count
    FROM 
        TopCustomers tc
    JOIN 
        AddressCounts ac ON tc.cd_marital_status = 'M'  
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    distinct_address_count
FROM 
    FinalReport
ORDER BY 
    cd_purchase_estimate DESC, full_name;