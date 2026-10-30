WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS average_order_value,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459508 AND 2459514 
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_profit,
        sd.total_orders,
        sd.average_order_value,
        sd.unique_customers,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS rank
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
),
TopCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS customer_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459508 AND 2459514 
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ti.rank,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    ti.total_orders,
    ti.average_order_value,
    tc.ws_bill_customer_sk,
    tc.total_spent,
    tc.order_count
FROM TopItems ti
JOIN TopCustomers tc ON ti.unique_customers = tc.order_count
WHERE ti.rank <= 10 AND tc.customer_rank <= 10
ORDER BY ti.total_profit DESC, tc.total_spent DESC;