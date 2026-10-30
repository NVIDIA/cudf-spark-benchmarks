
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 20000
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_profit,
        CASE 
            WHEN cs.total_profit IS NULL THEN 'No Profit'
            WHEN cs.total_profit > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM CustomerStats cs
),
SalesReturnStats AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(hvc.order_count, 0) AS order_count,
    COALESCE(hvc.total_profit, 0) AS total_profit,
    CASE 
        WHEN COALESCE(hvc.total_profit, 0) > 5000 THEN 'Premium'
        ELSE 'Standard'
    END AS customer_class,
    r.return_count,
    r.total_return_amt
FROM customer cu
LEFT JOIN HighValueCustomers hvc ON cu.c_customer_sk = hvc.c_customer_sk
LEFT JOIN SalesReturnStats r ON cu.c_customer_sk = r.wr_returning_customer_sk
WHERE 
    (hvc.customer_type = 'High Value' OR r.return_count > 5)
    AND hvc.customer_type IS NOT NULL
ORDER BY 
    hvc.total_profit DESC NULLS LAST,
    r.total_return_amt ASC NULLS FIRST
LIMIT 100;
