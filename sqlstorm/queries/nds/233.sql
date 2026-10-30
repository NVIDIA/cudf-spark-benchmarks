
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
SalesData AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
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
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
RankedCustomers AS (
    SELECT
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.customer_sk
)
SELECT 
    r.cd_gender,
    COUNT(*) AS customer_count,
    AVG(r.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(r.total_returns) AS total_returns,
    SUM(r.total_return_amount) AS total_return_amount,
    SUM(r.total_sales) AS total_sales
FROM 
    RankedCustomers r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.cd_gender
ORDER BY 
    avg_purchase_estimate DESC;
