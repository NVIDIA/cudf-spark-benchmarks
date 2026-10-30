
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender IS NOT NULL
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT rr.sr_customer_sk) AS unique_returning_customers,
    SUM(COALESCE(rr.total_return_amount, 0)) AS total_returns,
    AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS average_purchase_estimate
FROM 
    CustomerAddresses ca
LEFT JOIN 
    RankedReturns rr ON ca.c_customer_sk = rr.sr_customer_sk AND rr.rnk = 1
LEFT JOIN 
    CustomerDemographics cd ON ca.c_customer_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT rr.sr_customer_sk) > 5 OR AVG(cd.cd_purchase_estimate) > 300
ORDER BY 
    total_returns DESC, average_purchase_estimate DESC;
