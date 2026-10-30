
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS recent_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_address_id ORDER BY d.d_date DESC) AS rn
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX', 'NY')
)
SELECT 
    ad.ca_address_id,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    ad.full_name,
    ad.recent_purchase_date
FROM 
    AddressDetails ad
WHERE 
    ad.rn = 1
ORDER BY 
    ad.ca_city, ad.full_name;
