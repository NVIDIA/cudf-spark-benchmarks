
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_returned_value,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
PopularItem AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    ORDER BY 
        return_count DESC
    LIMIT 1
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
),
CustomerAddress AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        COALESCE(ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type, 'Unknown Address') AS full_address
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COUNT(DISTINCT cr.sr_customer_sk) AS customers_with_returns,
    SUM(cr.total_returned_items) AS total_items_returned,
    SUM(cr.total_returned_value) AS total_value_returned,
    cd.total_dependents,
    cd.avg_purchase_estimate,
    (SELECT COUNT(*) FROM PopularItem) AS most_returned_item_count
FROM 
    CustomerReturns cr
JOIN 
    CustomerAddress ca ON cr.sr_customer_sk = ca.c_customer_sk
JOIN 
    CustomerDemographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL AND 
    ca.ca_country IS NOT NULL AND 
    (cd.total_dependents > 0 OR cd.avg_purchase_estimate > 100) 
GROUP BY 
    ca.ca_city, ca.ca_state, ca.ca_country, cd.total_dependents, cd.avg_purchase_estimate
ORDER BY 
    total_value_returned DESC
LIMIT 10;
