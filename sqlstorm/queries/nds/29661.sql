
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
IncomeEducation AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ae.full_address,
    ae.ca_city,
    ae.ca_state,
    ae.ca_zip,
    ie.ib_lower_bound,
    ie.ib_upper_bound,
    ie.hd_buy_potential,
    MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ae ON cd.c_customer_sk = ae.ca_address_sk
JOIN 
    IncomeEducation ie ON cd.c_customer_sk = ie.hd_demo_sk
GROUP BY 
    cd.full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
    ae.full_address, ae.ca_city, ae.ca_state, ae.ca_zip,
    ie.ib_lower_bound, ie.ib_upper_bound, ie.hd_buy_potential
HAVING 
    MAX(cd.cd_purchase_estimate) >= 1000
ORDER BY 
    cd.full_name ASC, max_purchase_estimate DESC;
