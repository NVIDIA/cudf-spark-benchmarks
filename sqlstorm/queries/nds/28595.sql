
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemographicsDetails AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CONCAT(cd_education_status, ' - ', cd_credit_rating) AS education_credit,
        cd_purchase_estimate
    FROM customer_demographics
),
MergedData AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        dd.d_date AS sales_date,
        dd.d_month_seq,
        dd.d_year,
        dd.d_dow,
        dd.d_moy,
        dd.d_dom,
        dd.d_current_month,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.education_credit,
        dem.cd_purchase_estimate
    FROM customer c
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
    JOIN DemographicsDetails dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
)
SELECT
    MD.full_name,
    MD.full_address,
    MD.ca_city,
    MD.ca_state,
    ad.ca_zip,
    ad.ca_country,
    MD.sales_date,
    MD.d_month_seq,
    MD.d_year,
    MD.cd_gender,
    MD.cd_marital_status,
    MD.education_credit,
    MD.cd_purchase_estimate
FROM MergedData MD
JOIN AddressDetails ad ON MD.full_address = ad.full_address  -- Ensuring the ca_zip and ca_country are selected properly
WHERE MD.cd_purchase_estimate > 1000
ORDER BY MD.d_year DESC, MD.d_month_seq DESC;
