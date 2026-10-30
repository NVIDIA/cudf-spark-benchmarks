
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr.sr_return_amt, 0) AS return_amount,
        COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0) AS adjusted_profit,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number AND ws.ws_item_sk = sr.sr_item_sk
),
ProfitSummary AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.adjusted_profit) AS total_profit,
        COUNT(sd.ws_order_number) AS order_count
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        ci.purchase_rank = 1
    GROUP BY 
        ci.c_first_name, ci.c_last_name
)
SELECT 
    ps.c_first_name,
    ps.c_last_name,
    ps.total_profit,
    ps.order_count,
    CASE 
        WHEN ps.total_profit IS NULL THEN 'No Profit'
        WHEN ps.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    ProfitSummary ps
WHERE 
    ps.total_profit > 1000
ORDER BY 
    ps.total_profit DESC;
