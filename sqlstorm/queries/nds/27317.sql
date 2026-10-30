
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(ca_gmt_offset) AS average_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerGenderStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        SUM(cd_dep_count) AS total_dependent_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
DateProcessing AS (
    SELECT 
        d_year,
        COUNT(*) AS transaction_count,
        MAX(d_date) AS last_transaction_date,
        MIN(d_date) AS first_transaction_date
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.average_gmt_offset,
    g.cd_gender,
    g.customer_count,
    g.average_purchase_estimate,
    g.total_dependent_count,
    d.transaction_count,
    d.last_transaction_date,
    d.first_transaction_date
FROM 
    AddressSummary AS a
JOIN 
    CustomerGenderStats AS g ON a.address_count > 100
JOIN 
    DateProcessing AS d ON d.transaction_count > 2000
WHERE 
    a.ca_state IN ('CA', 'NY')
ORDER BY 
    a.address_count DESC, g.customer_count DESC;
