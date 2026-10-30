
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
RichCustomers AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returned, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    SUM(CASE WHEN r.total_returned > 0 THEN 1 ELSE 0 END) OVER (PARTITION BY c.c_customer_id) AS return_flag,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate
FROM 
    customer c
LEFT JOIN 
    SalesSummary s ON c.c_customer_sk = s.ws_ship_customer_sk
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.wr_returning_customer_sk
JOIN 
    RichCustomers rc ON c.c_current_cdemo_sk = rc.cd_demo_sk
WHERE 
    rc.rank <= 10 AND rc.cd_gender = 'F'
ORDER BY 
    c.c_last_name, c.c_first_name;
