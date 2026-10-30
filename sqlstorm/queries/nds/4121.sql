
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
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
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    COALESCE(cd.cd_gender, 'Not Specified') AS gender,
    COALESCE(cd.cd_marital_status, 'Not Specified') AS marital_status,
    COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
    COALESCE(SUM(cr.total_returned), 0) AS total_returned,
    COALESCE(SUM(cr.return_count), 0) AS return_count,
    COALESCE(SUM(cr.total_return_amount), 0) AS total_return_amount,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
GROUP BY 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_credit_rating, 
    ss.total_sales, 
    ss.order_count
HAVING 
    COALESCE(ss.total_sales, 0) > 1000 OR COALESCE(return_count, 0) > 5
ORDER BY 
    total_sales DESC, return_count DESC;
