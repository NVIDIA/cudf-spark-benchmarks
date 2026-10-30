
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.order_count
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.profit_rank <= 10
),
StoreReturnsData AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.sr_customer_sk
),
FinalReport AS (
    SELECT 
        hc.c_customer_sk,
        hc.c_first_name,
        hc.c_last_name,
        hc.total_net_profit,
        hc.order_count,
        COALESCE(sr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sr.return_count, 0) AS return_count,
        (hc.total_net_profit - COALESCE(sr.total_return_amt, 0)) AS net_profit_after_returns,
        CASE 
            WHEN (hc.total_net_profit - COALESCE(sr.total_return_amt, 0)) < 0 THEN 'Negative Profit'
            WHEN (hc.total_net_profit - COALESCE(sr.total_return_amt, 0)) = 0 THEN 'Break Even'
            ELSE 'Positive Profit' 
        END AS profit_status
    FROM 
        HighValueCustomers AS hc
    LEFT JOIN 
        StoreReturnsData AS sr ON hc.c_customer_sk = sr.sr_customer_sk
)
SELECT
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_net_profit,
    f.order_count,
    f.total_return_amt,
    f.return_count,
    f.net_profit_after_returns,
    f.profit_status
FROM 
    FinalReport AS f
WHERE 
    f.net_profit_after_returns > 0
ORDER BY 
    f.net_profit_after_returns DESC;
