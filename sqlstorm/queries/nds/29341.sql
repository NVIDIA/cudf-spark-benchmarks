WITH AddressDetails AS (
    SELECT 
        DISTINCT ca_state,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state, ca_city, ca_street_number, ca_street_name, ca_street_type
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
WebSalesDetails AS (
    SELECT 
        wp_url,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_page wp
    JOIN 
        web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk
    GROUP BY 
        wp_url
)
SELECT 
    ad.ca_state,
    ad.ca_city,
    ad.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.avg_purchase_estimate,
    d.total_dependents,
    w.wp_url,
    w.total_sales,
    w.order_count
FROM 
    AddressDetails ad
CROSS JOIN 
    Demographics d
JOIN 
    WebSalesDetails w ON d.cd_gender = 'M' AND d.cd_marital_status = 'M' 
ORDER BY 
    ad.ca_state, ad.ca_city, ad.full_address;