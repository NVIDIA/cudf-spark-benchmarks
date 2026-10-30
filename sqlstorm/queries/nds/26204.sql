
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Address_Details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS addr_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
),
Customer_Cheers AS (
    SELECT 
        rc.c_customer_id,
        rc.full_name,
        ad.ca_city,
        ad.ca_state,
        ad.addr_count,
        CASE WHEN rc.rank <= 10 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_type
    FROM 
        Ranked_Customers rc
    JOIN 
        Address_Details ad ON rc.c_customer_id = ad.ca_address_id
)
SELECT 
    cc.full_name,
    cc.ca_city,
    cc.ca_state,
    cc.customer_type
FROM 
    Customer_Cheers cc
WHERE 
    cc.ca_state = 'CA'
ORDER BY 
    cc.customer_type DESC, 
    cc.full_name;
