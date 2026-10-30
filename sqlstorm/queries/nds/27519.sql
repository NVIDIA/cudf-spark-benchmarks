
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS rank
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
ConcatenatedInfo AS (
    SELECT 
        CONCAT(ca_city, ', ', ca_state, ' - ', ca_country) AS address_details,
        rank
    FROM 
        RankedAddresses
    WHERE 
        rank <= 5
),
SalesAndInfo AS (
    SELECT 
        ws_sales_price,
        cs_sales_price,
        address_details
    FROM 
        web_sales ws
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    JOIN 
        ConcatenatedInfo ci ON ws.ws_bill_addr_sk = ci.rank
)
SELECT 
    address_details,
    AVG(ws_sales_price) AS avg_web_sales_price,
    AVG(cs_sales_price) AS avg_catalog_sales_price,
    COUNT(*) AS record_count
FROM 
    SalesAndInfo
GROUP BY 
    address_details
ORDER BY 
    record_count DESC;
