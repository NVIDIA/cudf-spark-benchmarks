
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
CustomerSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
), 
WebSiteSummary AS (
    SELECT 
        web_country,
        COUNT(DISTINCT web_site_id) AS total_websites,
        AVG(LENGTH(web_name)) AS avg_web_name_length
    FROM 
        web_site
    GROUP BY 
        web_country
)
SELECT 
    asum.ca_state,
    asum.unique_addresses,
    asum.avg_street_name_length,
    asum.max_street_name_length,
    csum.cd_gender,
    csum.total_customers,
    csum.avg_dependents,
    csum.max_purchase_estimate,
    wsum.web_country,
    wsum.total_websites,
    wsum.avg_web_name_length
FROM 
    AddressSummary asum
JOIN 
    CustomerSummary csum ON 1=1
JOIN 
    WebSiteSummary wsum ON 1=1
ORDER BY 
    asum.ca_state, csum.cd_gender, wsum.web_country;
