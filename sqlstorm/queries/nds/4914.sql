
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
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
        c.c_first_name,
        c.c_last_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)

SELECT 
    CD.c_customer_sk,
    CD.c_first_name,
    CD.c_last_name,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.cd_credit_rating,
    COALESCE(SD.total_sales, 0) AS total_sales,
    COALESCE(CR.total_returned, 0) AS total_returned,
    COALESCE(CR.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(SD.total_sales, 0) > 0 THEN
            (COALESCE(CR.total_returned, 0) * 100.0 / COALESCE(SD.total_sales, 1))
        ELSE 0 
    END AS return_rate_percentage
FROM 
    CustomerDemographics CD
LEFT JOIN 
    SalesData SD ON CD.c_customer_sk = SD.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns CR ON CD.c_customer_sk = CR.sr_customer_sk
WHERE 
    CD.cd_credit_rating = 'AAA'
    AND (CD.cd_gender = 'F' OR CD.cd_marital_status = 'M')
ORDER BY 
    return_rate_percentage DESC, 
    total_sales DESC;
