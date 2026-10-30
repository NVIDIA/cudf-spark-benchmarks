
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), ProductSales AS (
    SELECT 
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk, ws_item_sk
), CustomerDemographics AS (
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
), SalesData AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ps.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ps.total_sales_amount, 0) AS total_sales_amount
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        ProductSales ps ON cd.c_customer_sk = ps.ws_ship_customer_sk
), Summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.total_return_quantity) AS total_return_quantity,
        SUM(cd.total_return_amount) AS total_return_amount,
        SUM(cd.total_quantity_sold) AS total_quantity_sold,
        SUM(cd.total_sales_amount) AS total_sales_amount
    FROM 
        SalesData cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    *,
    total_sales_amount - total_return_amount AS net_sales,
    CASE 
        WHEN total_sales_amount = 0 THEN 0 
        ELSE (total_return_amount / total_sales_amount) * 100 
    END AS return_rate_percentage
FROM 
    Summary
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
