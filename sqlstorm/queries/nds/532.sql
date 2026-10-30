
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_qty,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS total_orders_returned
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sold_qty,
        SUM(ws_net_paid) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS total_orders_sold
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.gender,
    cd.cd_marital_status AS marital_status,
    cd.cd_education_status AS education_status,
    COALESCE(SD.total_sold_qty, 0) AS sales_quantity,
    COALESCE(CR.total_returned_qty, 0) AS returned_quantity,
    (COALESCE(SD.total_sold_qty, 0) - COALESCE(CR.total_returned_qty, 0)) AS net_sales_quantity,
    COALESCE(SD.total_sales_amt, 0) AS total_sales_amount,
    COALESCE(CR.total_return_amt, 0) AS total_return_amount,
    (COALESCE(SD.total_sales_amt, 0) - COALESCE(CR.total_return_amt, 0)) AS net_sales_amount
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesData SD ON cd.c_customer_sk = SD.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns CR ON cd.c_customer_sk = CR.wr_returning_customer_sk
WHERE 
    (cd.cd_purchase_estimate > 1000 AND cd.cd_credit_rating = 'Good' AND cd.cd_marital_status = 'M') 
    OR (cd.cd_purchase_estimate <= 500 AND cd.cd_credit_rating = 'Bad' AND cd.cd_marital_status = 'S')
ORDER BY 
    net_sales_amount DESC
LIMIT 100;
