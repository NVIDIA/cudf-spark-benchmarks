
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.full_address
),
RankedDemographics AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_orders DESC) AS order_rank
    FROM 
        Demographics
)
SELECT 
    c_customer_id, 
    c_first_name, 
    c_last_name, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    full_address, 
    total_orders 
FROM 
    RankedDemographics 
WHERE 
    order_rank <= 5
ORDER BY 
    cd_gender, total_orders DESC;
