
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ab.full_address,
        ab.ca_city,
        ab.ca_state,
        ab.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ab ON c.c_current_addr_sk = ab.ca_address_sk
),
SalesCount AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        COUNT(ws.ws_order_number) AS total_web_sales,
        COUNT(cs.cs_order_number) AS total_catalog_sales,
        COUNT(ss.ss_ticket_number) AS total_store_sales
    FROM 
        CustomerDetails c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    sc.total_web_sales,
    sc.total_catalog_sales,
    sc.total_store_sales
FROM 
    CustomerDetails cd
JOIN 
    SalesCount sc ON cd.c_customer_sk = sc.customer_sk
WHERE 
    cd.cd_purchase_estimate > 5000
ORDER BY 
    sc.total_web_sales DESC, sc.total_catalog_sales DESC, sc.total_store_sales DESC
LIMIT 100;
