
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
), CustomerDetails AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
), CombinedDetails AS (
    SELECT 
        ad.ca_city, 
        ad.ca_state, 
        ad.full_address, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.total_purchase_estimate, 
        cd.demographic_count,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_city, ad.ca_state ORDER BY cd.total_purchase_estimate DESC) AS rank
    FROM 
        AddressDetails ad
    JOIN 
        CustomerDetails cd 
    ON 
        ad.address_count > 10
)
SELECT 
    cd.ca_city, 
    cd.ca_state, 
    cd.full_address, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.total_purchase_estimate, 
    cd.demographic_count
FROM 
    CombinedDetails cd
WHERE 
    cd.rank <= 5
ORDER BY 
    cd.ca_state, cd.ca_city, cd.rank;
