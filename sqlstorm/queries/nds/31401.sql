
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
RankedSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_profit,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.total_profit DESC) AS item_rank
    FROM SalesCTE s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_order_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        cs.order_count,
        cs.total_order_profit
    FROM customer c
    JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.total_order_profit > (
        SELECT AVG(total_order_profit) FROM CustomerStats
    )
)
SELECT 
    hvc.c_customer_sk,
    hvc.order_count,
    hvc.total_order_profit,
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_profit,
    ROW_NUMBER() OVER (PARTITION BY hvc.c_customer_sk ORDER BY hvc.total_order_profit DESC) AS customer_rank
FROM HighValueCustomers hvc
JOIN RankedSales rs ON hvc.total_order_profit = rs.total_profit
LEFT JOIN item i ON rs.ws_item_sk = i.i_item_sk
WHERE i.i_current_price > (
    SELECT AVG(i_current_price) FROM item
)
ORDER BY hvc.c_customer_sk, customer_rank;
