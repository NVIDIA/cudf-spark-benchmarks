
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(COALESCE(ca_street_number, '')) + 
        LENGTH(COALESCE(ca_street_name, '')) + 
        LENGTH(COALESCE(ca_street_type, '')) AS address_length
    FROM 
        customer_address
), 
CustomerVisitCount AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT w.web_site_sk) AS visit_count
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    a.ca_address_sk,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    cvc.visit_count,
    a.address_length
FROM 
    AddressData a
JOIN 
    CustomerVisitCount cvc ON a.ca_address_sk = cvc.c_customer_sk
ORDER BY 
    a.address_length DESC,
    cvc.visit_count DESC
LIMIT 100;
