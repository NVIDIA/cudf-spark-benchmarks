
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        d_year,
        d_month_seq
    FROM date_dim
    WHERE d_year >= 2020
),
SalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM store_sales
    GROUP BY ss_store_sk
),
FinalReport AS (
    SELECT 
        ad.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        SUM(sd.total_sales) AS total_store_sales,
        SUM(sd.transaction_count) AS transaction_count
    FROM AddressData ad
    JOIN CustomerDemographics cd ON cd.cd_demo_sk = ad.ca_address_sk
    JOIN SalesData sd ON sd.ss_store_sk = ad.ca_address_sk
    JOIN DateDetails dd ON dd.d_date_sk = sd.ss_store_sk -- Assuming sd.ss_ticket_number was intended to join on d_date_sk
    GROUP BY ad.full_address, cd.cd_gender, cd.cd_marital_status, dd.d_year
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    d_year,
    total_store_sales,
    transaction_count
FROM FinalReport
ORDER BY total_store_sales DESC, transaction_count DESC;
