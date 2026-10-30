
WITH AddressDetails AS (
    SELECT
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM
        customer_address
    GROUP BY
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),

CustomerDemographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM
        customer_demographics
    GROUP BY
        cd_gender, cd_marital_status, cd_education_status
),

DateSummary AS (
    SELECT
        d_year,
        d_month_seq,
        COUNT(*) AS transaction_count,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    JOIN
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY
        d_year, d_month_seq
)

SELECT
    ad.ca_city,
    ad.ca_state,
    ad.full_address,
    ad.address_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.total_purchase_estimate,
    ds.d_year,
    ds.d_month_seq,
    ds.transaction_count,
    ds.total_sales
FROM
    AddressDetails ad
JOIN
    CustomerDemographics cd ON (ad.address_count > 10) 
JOIN
    DateSummary ds ON (ds.transaction_count > 100) 
ORDER BY
    ds.total_sales DESC, ad.address_count DESC, cd.total_purchase_estimate DESC
LIMIT 50;
