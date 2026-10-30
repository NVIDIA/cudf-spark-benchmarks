WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
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
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        cu.total_sales,
        cu.total_orders,
        cr.total_returns,
        cr.total_return_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        SalesSummary cu ON c.c_customer_sk = cu.customer_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_orders,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_return_amount, 0) AS total_return_amount,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.cd_purchase_estimate
FROM 
    FinalReport f
WHERE 
    f.total_sales > 1000 
ORDER BY 
    total_sales DESC;