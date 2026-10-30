
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA' 
        AND ca_state IN ('CA', 'NY', 'TX')
), DemographicDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.street_name_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
), SalesAggregation AS (
    SELECT 
        ddd.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        DemographicDetails ddd ON ws.ws_bill_customer_sk = ddd.c_customer_sk
    GROUP BY 
        ddd.c_customer_sk
)
SELECT 
    ddd.c_customer_sk,
    ddd.c_first_name,
    ddd.c_last_name,
    ddd.cd_gender,
    ddd.cd_marital_status,
    ddd.cd_education_status,
    ddd.cd_purchase_estimate,
    sa.total_spent,
    sa.order_count,
    ddd.full_address,
    ddd.street_name_length
FROM 
    DemographicDetails ddd
LEFT JOIN 
    SalesAggregation sa ON ddd.c_customer_sk = sa.c_customer_sk
ORDER BY 
    sa.total_spent DESC
LIMIT 10;
