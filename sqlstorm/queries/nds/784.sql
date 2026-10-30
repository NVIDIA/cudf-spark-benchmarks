
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
),
HighValueReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 1
    GROUP BY 
        sr_returned_date_sk, 
        sr_return_time_sk, 
        sr_item_sk, 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    hvr.total_returned_quantity,
    hvr.total_return_amount,
    ss.total_quantity_sold,
    ss.total_net_profit
FROM 
    RankedCustomers rc
LEFT JOIN 
    HighValueReturns hvr ON rc.c_customer_sk = hvr.sr_customer_sk
FULL OUTER JOIN 
    SalesSummary ss ON hvr.sr_item_sk = ss.ws_item_sk
WHERE 
    rc.rnk <= 10
    AND (hvr.total_return_amount IS NOT NULL OR ss.total_net_profit > 100)
ORDER BY 
    rc.cd_gender, 
    hvr.total_return_amount DESC NULLS LAST;
