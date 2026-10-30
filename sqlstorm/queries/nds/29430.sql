
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT o.ws_order_number) AS total_orders,
        SUM(o.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FinalDetails AS (
    SELECT 
        cs.full_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cs.total_orders,
        cs.total_spent
    FROM 
        CustomerSummary AS cs
    JOIN 
        customer_address AS ca ON cs.c_customer_id = ca.ca_address_id
    JOIN 
        AddressDetails AS ad ON ad.full_address = CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)
)

SELECT 
    fd.full_name,
    fd.cd_gender,
    fd.cd_marital_status,
    fd.cd_education_status,
    fd.full_address,
    fd.ca_city,
    fd.ca_state,
    fd.ca_zip,
    fd.total_orders,
    fd.total_spent
FROM 
    FinalDetails AS fd
WHERE 
    fd.total_spent > 1000
ORDER BY 
    fd.total_spent DESC, 
    fd.full_name;
