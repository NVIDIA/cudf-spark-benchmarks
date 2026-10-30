
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
), 
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk AS rc_customer_sk,
        cr.return_count,
        cr.total_returned,
        cr.total_returned_amt,
        CASE 
            WHEN cr.return_count > 5 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS returner_type
    FROM 
        CustomerReturns cr
    WHERE 
        cr.return_count > 0
), 
CustomerDemographic AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cd.cd_dep_count, 0) AS dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_price
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cr.rc_customer_sk AS customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    sd.total_net_profit,
    cd.dep_count,
    cr.returner_type
FROM 
    HighReturnCustomers cr
JOIN 
    CustomerDemographic cd ON cr.rc_customer_sk = cd.c_customer_sk
LEFT JOIN 
    SalesData sd ON cr.rc_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_gender IS NOT NULL 
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND (sd.total_net_profit IS NULL OR sd.total_net_profit < 100) 
ORDER BY 
    cr.return_count DESC, 
    cd.cd_purchase_estimate DESC
LIMIT 10;
