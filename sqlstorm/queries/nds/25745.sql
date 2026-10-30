
WITH AddressTerms AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ca_country, 
        TRIM(LOWER(ca_street_name)) AS normalized_street_name,
        LENGTH(TRIM(ca_street_name)) AS street_length,
        REGEXP_REPLACE(TRIM(ca_street_name), '[^a-zA-Z0-9 ]', '') AS street_name_clean
    FROM customer_address
),
Promotions AS (
    SELECT 
        p.p_promo_name,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk,
        LENGTH(p.p_channel_details) AS channel_details_length
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
SalesInfo AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS num_transactions
    FROM web_sales
    GROUP BY ws_item_sk
),
DetailedInfo AS (
    SELECT 
        a.ca_address_sk,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        p.p_promo_name,
        s.total_sales,
        s.num_transactions,
        a.street_length,
        p.channel_details_length
    FROM AddressTerms a
    LEFT JOIN Promotions p ON a.ca_city LIKE '%' || p.p_promo_name || '%'
    LEFT JOIN SalesInfo s ON a.ca_address_sk = s.ws_item_sk
),
FinalMetrics AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_country,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(street_length) AS avg_street_length,
        SUM(total_sales) AS total_sales,
        SUM(num_transactions) AS total_transactions,
        AVG(channel_details_length) AS avg_channel_length
    FROM DetailedInfo
    GROUP BY ca_city, ca_state, ca_country
)
SELECT 
    ca_city, 
    ca_state, 
    ca_country, 
    unique_addresses, 
    avg_street_length, 
    total_sales, 
    total_transactions, 
    avg_channel_length
FROM FinalMetrics
ORDER BY total_sales DESC, unique_addresses DESC;
