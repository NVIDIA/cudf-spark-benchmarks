
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_items,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned_items,
        SUM(wr_return_amt) AS total_web_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_web_sales,
        SUM(ws_net_paid) AS total_sales_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459933 AND 2460562   
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(cr.total_returned_items, 0) AS total_returned_items,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(wr.total_web_returned_items, 0) AS total_web_returned_items,
    COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount,
    COALESCE(sd.total_web_sales, 0) AS total_web_sales,
    COALESCE(sd.total_sales_revenue, 0) AS total_sales_revenue
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    WebReturns wr ON cd.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.customer_sk
WHERE 
    (cd.cd_gender = 'M' AND cd.cd_purchase_estimate > 500) OR 
    (cd.cd_marital_status = 'S' AND cd.cd_dep_count IS NOT NULL) 
ORDER BY 
    total_sales_revenue DESC
LIMIT 100;
