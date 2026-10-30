
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cc.cc_name AS call_center_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_month DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        call_center cc ON c.c_first_sales_date_sk = cc.cc_call_center_sk
    WHERE 
        cd.cd_gender IN ('M', 'F')
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        COUNT(*) AS address_count
    FROM 
        customer_address ca 
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ca.ca_zip
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    ca.address_count
FROM 
    RankedCustomers rc
JOIN 
    CustomerAddresses ca ON rc.c_customer_sk = ca.ca_address_sk
WHERE 
    rc.rank <= 5 AND
    (ca.ca_zip LIKE '9%' OR ca.ca_city LIKE '%City%')
ORDER BY 
    rc.cd_gender DESC, rc.full_name ASC;
