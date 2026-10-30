
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_ticket_number,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
TopReturns AS (
    SELECT 
        r.sr_returned_date_sk,
        r.sr_item_sk,
        r.sr_customer_sk,
        r.sr_ticket_number,
        r.sr_return_quantity,
        SUM(r.sr_return_quantity) OVER (PARTITION BY r.sr_item_sk) AS total_returned
    FROM 
        RankedReturns r
    WHERE 
        r.return_rank = 1
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(r.total_returned), 0) AS total_quantity_returned,
        COUNT(r.sr_ticket_number) AS total_return_count
    FROM 
        customer c
    LEFT JOIN 
        TopReturns r ON c.c_customer_sk = r.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
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
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
FinalReport AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cr.total_quantity_returned,
        cr.total_return_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cr.total_quantity_returned > 0
        AND cd.cd_gender IS NOT NULL
)
SELECT 
    f.*,
    CASE 
        WHEN f.total_quantity_returned > 10 THEN 'High Returner'
        WHEN f.total_return_count = 1 THEN 'Single Return'
        ELSE 'Other'
    END AS return_category,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
    CONCAT('Address: ', COALESCE(ca.ca_street_number, 'N/A'), ' ', COALESCE(ca.ca_street_name, 'N/A')) AS full_address
FROM 
    FinalReport f
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = f.c_customer_sk
WHERE 
    (f.total_quantity_returned IS NULL OR f.total_quantity_returned > 0)
ORDER BY 
    f.total_quantity_returned DESC,
    f.c_customer_sk
LIMIT 50;
