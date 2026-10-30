
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 365 
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(CASE WHEN ws.ws_net_profit IS NULL THEN 0 ELSE ws.ws_net_profit END), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(cin.ib_upper_bound) AS max_income_band
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band cin ON hd.hd_income_band_sk = cin.ib_income_band_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.*, 
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM
        CustomerStats c
)
SELECT 
    t.ws_item_sk,
    t.rank,
    c.c_first_name,
    c.c_last_name,
    c.total_profit,
    COALESCE(c.max_income_band, -1) AS income_band,
    CASE 
        WHEN c.total_orders = 0 THEN 'No Orders'
        ELSE CONCAT(c.total_orders, ' Orders')
    END AS order_status
FROM
    RankedSales t
JOIN TopCustomers c ON t.ws_item_sk = c.c_customer_sk
WHERE
    t.rank <= 5
ORDER BY
    t.ws_item_sk, t.rank;
