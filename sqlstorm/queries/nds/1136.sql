
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_ship_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_credit_rating,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    SUM(COALESCE(sd.total_sales, 0)) AS total_sales,
    SUM(COALESCE(cr.total_returns, 0)) AS total_returns,
    SUM(COALESCE(cr.total_return_amount, 0)) AS total_return_amount,
    COUNT(DISTINCT COALESCE(sd.total_orders, 0)) AS total_orders,
    AVG(sd.avg_sales_price) AS avg_sales_price,
    MAX(cr.total_return_amount) AS max_return_amount,
    MIN(cr.total_return_amount) AS min_return_amount,
    CASE 
        WHEN SUM(COALESCE(cr.total_return_amount, 0)) > 100 THEN 'High Returns'
        ELSE 'Low Returns'
    END AS return_category
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
GROUP BY 
    cd.c_customer_sk,
    cd.cd_gender
ORDER BY 
    total_sales DESC, 
    total_returns DESC
LIMIT 100;
