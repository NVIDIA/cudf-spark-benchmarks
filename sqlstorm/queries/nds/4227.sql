
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons
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
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_credit_rating, 'N/A') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnAndSales AS (
    SELECT 
        cd.c_customer_sk AS customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_coupons, 0) AS total_coupons
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.customer_sk
)
SELECT 
    r.customer_sk,
    r.cd_gender,
    r.cd_marital_status,
    r.total_returns,
    r.total_return_amt,
    r.total_sales,
    r.total_coupons,
    (r.total_sales - r.total_return_amt) AS net_sales,
    CASE 
        WHEN r.total_sales > 0 THEN (CAST(r.total_returns AS decimal) / r.total_sales) * 100
        ELSE NULL 
    END AS return_rate_percentage
FROM 
    ReturnAndSales r
WHERE 
    r.total_coupons > 100
ORDER BY 
    net_sales DESC
LIMIT 10;
