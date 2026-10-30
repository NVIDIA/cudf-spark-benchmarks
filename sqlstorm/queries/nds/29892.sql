
WITH CustomerFullNames AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name
    FROM 
        customer c
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), ', ', TRIM(ca.ca_city), ', ', TRIM(ca.ca_state), ' ', TRIM(ca.ca_zip)) AS full_address
    FROM 
        customer_address ca
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        CONCAT(TRIM(cd.cd_gender), ' ', TRIM(cd.cd_marital_status), ' ', TRIM(cd.cd_education_status)) AS demographics
    FROM 
        customer_demographics cd
),
SalesSum AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        cfn.full_name,
        ai.full_address,
        dm.demographics,
        ss.total_profit
    FROM 
        CustomerFullNames cfn
    LEFT JOIN 
        AddressInfo ai ON cfn.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        Demographics dm ON cfn.c_customer_sk = dm.cd_demo_sk
    LEFT JOIN 
        SalesSum ss ON cfn.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    demographics,
    COALESCE(total_profit, 0) AS total_profit
FROM 
    CustomerDetails
WHERE 
    full_name LIKE '%John%'
ORDER BY 
    total_profit DESC;
