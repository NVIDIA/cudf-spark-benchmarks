
WITH processed_addresses AS (
    SELECT 
        ca_city,
        UPPER(ca_street_name) AS upper_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_zip) AS zip_length,
        SUBSTR(ca_country, 1, 3) AS country_code
    FROM customer_address
), 
demographics AS (
    SELECT 
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        cd_purchase_estimate,
        REPLACE(cd_credit_rating, ' ', '') AS credit_rating
    FROM customer_demographics
), 
sales_summary AS (
    SELECT 
        ss_item_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_sales_price) AS total_revenue
    FROM store_sales
    GROUP BY ss_item_sk
)
SELECT 
    pa.ca_city,
    pa.upper_street_name,
    pa.full_address,
    pa.zip_length,
    pa.country_code,
    d.cd_gender,
    d.marital_status,
    d.cd_purchase_estimate,
    d.credit_rating,
    ss.total_sales,
    ss.total_revenue
FROM processed_addresses pa
JOIN demographics d ON pa.zip_length > 5
JOIN sales_summary ss ON ss.total_sales > 10
WHERE pa.ca_city LIKE 'New%' 
GROUP BY 
    pa.ca_city, 
    pa.upper_street_name, 
    pa.full_address, 
    pa.zip_length, 
    pa.country_code, 
    d.cd_gender, 
    d.marital_status, 
    d.cd_purchase_estimate, 
    d.credit_rating, 
    ss.total_sales, 
    ss.total_revenue
ORDER BY pa.ca_city, d.cd_purchase_estimate DESC, ss.total_revenue DESC
LIMIT 100;
