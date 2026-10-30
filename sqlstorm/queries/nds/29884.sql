
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_country, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 1000
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    JOIN 
        FilteredCustomers fc ON fc.c_customer_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        FilteredCustomers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    sd.total_quantity_sold,
    sd.total_sales
FROM 
    FilteredCustomers fc
JOIN 
    AddressInfo ai ON fc.c_customer_sk = ai.ca_address_sk
JOIN 
    SalesData sd ON fc.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
