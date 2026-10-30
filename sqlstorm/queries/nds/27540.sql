
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        SUBSTRING(ci.full_name, 1, 1) AS name_initial,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate
    FROM 
        CustomerInfo ci
    WHERE 
        ci.cd_purchase_estimate > 1000 AND
        ci.ca_state IN ('NY', 'CA') AND
        ci.cd_gender = 'F'
),
RankedCustomers AS (
    SELECT 
        fc.*,
        RANK() OVER (PARTITION BY fc.ca_state ORDER BY fc.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        FilteredCustomers fc
)
SELECT 
    rc.full_name,
    rc.ca_city,
    rc.ca_state,
    rc.cd_purchase_estimate,
    rc.purchase_rank
FROM 
    RankedCustomers rc
WHERE 
    rc.purchase_rank <= 10
ORDER BY 
    rc.ca_state, rc.purchase_rank;
