
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        COUNT(DISTINCT s.ss_ticket_number) AS total_orders,
        SUM(s.ss_net_profit) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_net_profit) DESC) AS customer_rank
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, d.d_year
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        sc.total_quantity,
        sc.total_profit,
        ROW_NUMBER() OVER (ORDER BY sc.total_profit DESC) AS item_rank
    FROM item i
    JOIN SalesCTE sc ON i.i_item_sk = sc.ws_item_sk
    WHERE sc.rank <= 10
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cc.total_orders,
        cc.total_spent,
        ROW_NUMBER() OVER (ORDER BY cc.total_spent DESC) AS customer_rank
    FROM customer c
    JOIN CustomerCTE cc ON c.c_customer_sk = cc.c_customer_sk
    WHERE cc.customer_rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    tc.customer_rank,
    ti.total_profit,
    ti.total_quantity
FROM TopItems ti
FULL OUTER JOIN TopCustomers tc ON ti.total_profit = tc.total_spent
WHERE (tc.total_orders > 0 OR ti.total_quantity > 0)
ORDER BY ti.total_profit DESC, tc.total_spent DESC;
