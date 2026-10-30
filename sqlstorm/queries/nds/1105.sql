
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_customer_sk,
    COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
    COALESCE(cd.cd_marital_status, 'UNKNOWN') AS marital_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN cr.return_count > 0 THEN 'Frequent Returner'
        ELSE 'General Customer'
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_customer_sk = cd.c_customer_sk
WHERE 
    (sd.total_sales IS NOT NULL AND sd.total_sales > 1000) OR 
    (cr.return_count IS NOT NULL AND cr.return_count > 1)
ORDER BY 
    total_sales DESC, 
    return_count ASC;
