
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT wr_order_number) AS transaction_count
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(ws_item_sk) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SD.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(CR.total_returned_amount, 0) AS total_returned_amount,
    CR.total_returned_quantity,
    CR.transaction_count,
    CASE 
        WHEN COALESCE(SD.total_sales_amount, 0) = 0 THEN 0
        ELSE COALESCE(CR.total_returned_amount, 0) / COALESCE(SD.total_sales_amount, 0) * 100 
    END AS return_rate_percentage
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesData SD ON cd.c_customer_sk = SD.customer_sk
LEFT JOIN 
    CustomerReturns CR ON cd.c_customer_sk = CR.customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND cd.cd_purchase_estimate > 1000
ORDER BY 
    return_rate_percentage DESC
LIMIT 10;
