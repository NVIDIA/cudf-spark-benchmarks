
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        COUNT(DISTINCT w.w_warehouse_sk) AS warehouse_count,
        SUM(CASE WHEN w.w_state = 'CA' THEN 1 ELSE 0 END) AS ca_warehouses
    FROM 
        RankedCustomers rc
    JOIN 
        customer_address ca ON rc.c_customer_sk = ca.ca_address_sk
    JOIN 
        warehouse w ON w.w_warehouse_sk = ca.ca_address_sk
    WHERE 
        rc.rank <= 10
    GROUP BY 
        rc.full_name, rc.cd_gender, rc.cd_marital_status, rc.cd_education_status
)
SELECT 
    f.full_name,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.warehouse_count,
    f.ca_warehouses,
    CONCAT('Customer: ', f.full_name, ', Gender: ', f.cd_gender, ', Marital Status: ', f.cd_marital_status, ', Education: ', f.cd_education_status) AS summary
FROM 
    FilteredCustomers f
ORDER BY 
    f.warehouse_count DESC;
