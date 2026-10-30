WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) AS street_number,
        TRIM(ca_street_name) AS street_name,
        TRIM(ca_street_type) AS street_type,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM customer_address
),
CombinedAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', street_number, street_name, street_type, city, state, zip) AS full_address
    FROM AddressParts
),
DistinctPromotions AS (
    SELECT DISTINCT 
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active
    FROM promotion p
    INNER JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
),
TopCities AS (
    SELECT 
        city,
        COUNT(*) AS address_count
    FROM AddressParts
    GROUP BY city
    ORDER BY address_count DESC
    LIMIT 5
)
SELECT 
    ca.ca_address_sk,
    ca.full_address,
    dp.p_promo_id,
    dp.p_promo_name,
    dp.p_discount_active,
    tc.city
FROM CombinedAddress ca
JOIN DistinctPromotions dp ON 1 = 1 
JOIN TopCities tc ON ca.full_address LIKE CONCAT('%', tc.city, '%')
ORDER BY ca.ca_address_sk, dp.p_promo_id;