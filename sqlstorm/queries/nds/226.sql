
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 501 AND 1500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_quantity,
        cd.cd_gender,
        cd.purchase_estimate_band
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
    ORDER BY 
        cr.total_return_amount DESC
    LIMIT 10
)
SELECT 
    tc.sr_customer_sk,
    tc.total_returns,
    tc.total_return_amount,
    tc.total_return_quantity,
    tc.cd_gender,
    tc.purchase_estimate_band,
    COALESCE(band_counts.medium_count, 0) AS medium_count,
    COALESCE(band_counts.high_count, 0) AS high_count
FROM 
    TopCustomers tc
LEFT JOIN (
    SELECT 
        purchase_estimate_band,
        COUNT(*) AS medium_count,
        SUM(CASE WHEN purchase_estimate_band = 'High' THEN 1 ELSE 0 END) AS high_count
    FROM 
        CustomerDemographics
    WHERE 
        cd_purchase_estimate BETWEEN 501 AND 1500 OR cd_purchase_estimate > 1500
    GROUP BY 
        purchase_estimate_band
) AS band_counts ON band_counts.purchase_estimate_band = tc.purchase_estimate_band
ORDER BY 
    tc.purchase_estimate_band, tc.total_return_amount DESC;
