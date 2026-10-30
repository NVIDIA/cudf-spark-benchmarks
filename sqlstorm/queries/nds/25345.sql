WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemoStats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
YearlyReturns AS (
    SELECT 
        EXTRACT(YEAR FROM d_date) AS return_year,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    JOIN 
        date_dim ON sr_returned_date_sk = d_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d_date)
)
SELECT 
    A.full_address,
    A.ca_city,
    A.ca_state,
    D.cd_gender,
    D.cd_marital_status,
    D.customer_count,
    D.avg_purchase_estimate,
    R.return_year,
    R.total_returns,
    R.total_return_amount
FROM 
    AddressParts A
JOIN 
    customer C ON A.ca_address_sk = C.c_current_addr_sk
JOIN 
    DemoStats D ON C.c_current_cdemo_sk = D.cd_demo_sk
JOIN 
    YearlyReturns R ON R.return_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
ORDER BY 
    A.ca_city, D.cd_gender;