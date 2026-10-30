
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS distinct_return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales_value,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
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
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    COALESCE(cd.cd_gender, 'U') AS gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
    COALESCE(cr.total_returned_quantity, 0) AS total_returns,
    COALESCE(ws.total_sales_value, 0) AS total_sales_value,
    ws.order_count,
    ws.sales_rank
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    WebSalesSummary ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (cd.cd_purchase_estimate > 100 OR cd.cd_credit_rating = 'Excellent')
    AND (cr.distinct_return_count IS NULL OR cr.distinct_return_count < 5)
ORDER BY 
    total_sales_value DESC, 
    total_returns ASC;
