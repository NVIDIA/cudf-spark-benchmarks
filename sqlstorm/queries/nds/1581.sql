
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        MAX(sr_returned_date_sk) AS last_return_date
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
HighReturnCustomers AS (
    SELECT 
        cr.*, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cr.total_return_amt_inc_tax > (
            SELECT AVG(total_return_amt_inc_tax) 
            FROM CustomerReturns
        )
), 
CustomerAddressInfo AS (
    SELECT 
        hrc.*, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_return_amt_inc_tax DESC) AS rank_within_income_band
    FROM 
        HighReturnCustomers hrc 
    LEFT JOIN 
        household_demographics hd ON hrc.sr_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_address ca ON hrc.sr_customer_sk = ca.ca_address_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_return_amt_inc_tax,
    ci.return_count,
    ci.last_return_date,
    ci.ca_city, 
    ci.ca_state,
    ci.ca_country,
    CASE 
        WHEN ci.rank_within_income_band = 1 THEN 'Top Returner' 
        ELSE 'Regular Returner' 
    END AS returner_category
FROM 
    CustomerAddressInfo ci
WHERE 
    ci.return_count > 1
ORDER BY 
    ci.total_return_amt_inc_tax DESC
LIMIT 100;
