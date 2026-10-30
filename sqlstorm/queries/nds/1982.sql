
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        sr_return_tax,
        sr_ticket_number,
        sr_net_loss,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        sr_return_quantity > 0
),
TopReturns AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.ca_city,
        cr.ca_state,
        SUM(cr.sr_return_quantity) AS total_returned,
        SUM(cr.sr_return_amt_inc_tax) AS total_returned_amt,
        SUM(cr.sr_net_loss) AS total_net_loss
    FROM 
        CustomerReturns cr
    WHERE 
        cr.rn = 1
    GROUP BY 
        cr.c_customer_sk, cr.c_first_name, cr.c_last_name, cr.ca_city, cr.ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    tr.c_customer_sk,
    tr.c_first_name,
    tr.c_last_name,
    tr.ca_city,
    tr.ca_state,
    tr.total_returned,
    tr.total_returned_amt,
    tr.total_net_loss,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM 
    TopReturns tr
JOIN 
    CustomerDemographics cd ON tr.c_customer_sk = cd.cd_demo_sk
WHERE 
    (tr.total_returned > 5 AND cd.customer_count > 10)
    OR 
    (tr.total_net_loss > 100.00 AND cd.cd_gender = 'F')
ORDER BY 
    tr.total_net_loss DESC, tr.total_returned_amt DESC;
