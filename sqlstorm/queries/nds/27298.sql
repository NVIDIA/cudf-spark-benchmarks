
WITH AddressDetails AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateAggregation AS (
    SELECT
        d_year,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        date_dim
    JOIN
        web_sales ON d_date_sk = ws_sold_date_sk
    JOIN
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        d_year
)
SELECT
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    da.d_year,
    da.total_customers,
    da.avg_purchase_estimate
FROM 
    AddressDetails ad
JOIN 
    CustomerInfo ci ON ci.cd_purchase_estimate > 1000
JOIN 
    DateAggregation da ON da.total_customers > 1000 
WHERE
    ad.ca_state = 'CA'
ORDER BY
    da.d_year DESC, ci.cd_purchase_estimate DESC
LIMIT 50;
