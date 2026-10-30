
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesCounts AS (
    SELECT 
        cd.c_customer_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.full_address,
    sc.order_count,
    ROUND(sc.total_spent, 2) AS total_spent
FROM 
    CustomerDetails cd
JOIN 
    SalesCounts sc ON cd.c_customer_sk = sc.c_customer_sk
ORDER BY 
    sc.total_spent DESC
LIMIT 50;
