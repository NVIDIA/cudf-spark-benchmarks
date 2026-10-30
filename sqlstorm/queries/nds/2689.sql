
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
), 
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(ws.total_net_profit, 0) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate >= 1000 AND 
        (ws.total_net_profit IS NULL OR ws.total_net_profit > 0) 
)
SELECT 
    hc.c_customer_sk, 
    hc.c_first_name || ' ' || hc.c_last_name AS customer_name, 
    hc.return_count,
    hc.total_net_profit,
    RANK() OVER (ORDER BY hc.total_net_profit DESC) AS profit_rank
FROM 
    HighValueCustomers hc
WHERE 
    hc.return_count < 5
ORDER BY 
    profit_rank
LIMIT 100;
