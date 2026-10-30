
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        MIN(cr_returned_date_sk) AS first_return_date,
        MAX(cr_returned_date_sk) AS last_return_date
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_sales_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
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
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    c.c_customer_sk AS c_customer_id,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    COALESCE(cr.return_count, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0.00) AS amount_returned,
    COALESCE(ss.total_sales_profit, 0.00) AS sales_profit,
    COALESCE(ss.total_orders, 0) AS num_orders,
    CASE 
        WHEN ss.avg_order_value IS NULL OR ss.avg_order_value = 0 THEN 'No Order'
        WHEN ss.avg_order_value < 100 THEN 'Low Value'
        ELSE 'High Value'
    END AS order_value_category,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ss.total_sales_profit DESC) AS rank_by_profit
FROM 
    customer c
JOIN 
    CustomerDemographics cd ON c.c_customer_sk = cd.c_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    (cd.cd_marital_status IS NULL OR cd.cd_marital_status <> 'S')
    AND (cd.cd_credit_rating IN ('Excellent', 'Good') OR cd.cd_credit_rating IS NULL)
    AND COALESCE(cr.return_count, 0) < 3
ORDER BY 
    cd.cd_gender, rank_by_profit;
