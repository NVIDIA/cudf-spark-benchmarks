
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ws.ws_bill_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS customer_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 1 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12 LIMIT 1)
    GROUP BY
        ws.ws_item_sk, ws.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        customer_rank,
        ws_bill_customer_sk,
        total_quantity,
        total_profit
    FROM
        SalesData
    WHERE
        customer_rank <= 5
),
ItemCategory AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_category
)
SELECT
    tc.ws_bill_customer_sk,
    SUM(tc.total_quantity) AS total_quantity,
    SUM(tc.total_profit) AS total_profit,
    ic.i_category,
    COUNT(ic.order_count) AS unique_orders,
    CASE 
        WHEN SUM(tc.total_profit) IS NULL THEN 0 
        ELSE SUM(tc.total_profit)
    END AS adjusted_profit
FROM
    TopCustomers tc
LEFT JOIN ItemCategory ic ON tc.ws_bill_customer_sk = ic.i_item_sk
GROUP BY
    tc.ws_bill_customer_sk, ic.i_category
ORDER BY
    total_profit DESC
LIMIT 10
