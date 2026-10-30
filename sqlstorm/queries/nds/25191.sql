
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' END,
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        da.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressConcat da ON c.c_current_addr_sk = da.ca_address_sk
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_quantity,
    ss.total_net_paid
FROM 
    CustomerDetails cs
JOIN 
    SalesSummary ss ON cs.cd_gender = ss.cd_gender AND cs.cd_marital_status = ss.cd_marital_status
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
