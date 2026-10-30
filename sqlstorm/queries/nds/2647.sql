
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count 
    FROM 
        customer_demographics
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(cr.total_returned_items, 0) AS total_returned_items,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status) AS demographic_info,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(cr.total_returned_amount, 0) DESC) AS state_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cr.total_returned_items IS NOT NULL AND cr.total_returned_items > 0)
    OR (cd.cd_credit_rating = 'High' AND cd.cd_purchase_estimate > 10000)
ORDER BY 
    ca.ca_city ASC, 
    state_rank DESC;
