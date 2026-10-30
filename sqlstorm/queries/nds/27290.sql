
WITH Address_Examples AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        ca_city,
        ca_state, 
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
),
Demographic_Examples AS (
    SELECT 
        cd_demo_sk, 
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        cd_purchase_estimate,
        COALESCE(NULLIF(cd_credit_rating, ''), 'Unknown') AS credit_rating
    FROM 
        customer_demographics
),
Sales_Examples AS (
    SELECT 
        ws_promo_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_promo_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.cd_gender,
    d.marital_status,
    d.cd_purchase_estimate,
    s.total_quantity,
    s.total_sales,
    s.total_discount
FROM 
    Address_Examples a
JOIN 
    Demographic_Examples d ON a.ca_address_sk = d.cd_demo_sk
LEFT JOIN 
    Sales_Examples s ON a.ca_address_sk = s.ws_promo_sk
WHERE 
    a.ca_zip LIKE '9%' AND 
    s.total_sales > 1000
ORDER BY 
    a.ca_city, d.cd_purchase_estimate DESC;
