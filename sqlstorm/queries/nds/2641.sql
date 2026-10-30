
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        MAX(sr_returned_date_sk) AS last_return_date
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        crsr.sr_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CustomerReturns crsr
    JOIN 
        customer c ON crsr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        crsr.total_returned_quantity > (
            SELECT 
                AVG(total_returned_quantity) 
            FROM 
                CustomerReturns
        )
),
CurrentMonthReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr_returned_date_sk) AS returns_this_month
    FROM 
        store_returns sr 
    JOIN 
        date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_month_seq = (
            SELECT 
                d_month_seq 
            FROM 
                date_dim 
            WHERE 
                d_date = DATE '2002-10-01'
        )
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    hrc.sr_customer_sk,
    hrc.ca_city,
    hrc.ca_state,
    hrc.ca_country,
    hrc.cd_gender,
    hrc.cd_marital_status,
    hrc.cd_credit_rating,
    COALESCE(cmr.returns_this_month, 0) AS returns_this_month
FROM 
    HighReturnCustomers hrc
LEFT JOIN 
    CurrentMonthReturns cmr ON hrc.sr_customer_sk = cmr.sr_customer_sk
ORDER BY 
    hrc.ca_city, 
    hrc.cd_gender DESC;
