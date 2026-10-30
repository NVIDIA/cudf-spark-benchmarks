
WITH  sales_trends AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_sold_date_sk
),

customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_order_price,
        MIN(ws.ws_sales_price) AS min_order_price
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),

anomalous_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.total_spent,
        ci.total_orders,
        ci.max_order_price,
        ci.min_order_price,
        CASE 
            WHEN ci.total_spent IS NULL OR ci.total_orders = 0 THEN 'No Spending'
            WHEN ci.total_spent > 10000 THEN 'High Roller'
            WHEN ci.max_order_price > 1000 THEN 'Big Spender'
            ELSE 'Average Customer'
        END AS customer_category
    FROM customer_info ci
    WHERE ci.total_spent IS NOT NULL OR ci.total_orders > 0
),

top_customers AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_first_name,
        ac.c_last_name,
        ac.total_spent,
        ac.customer_category,
        ROW_NUMBER() OVER (ORDER BY ac.total_spent DESC) AS customer_rank
    FROM anomalous_customers ac
    WHERE ac.total_spent > 5000
),

shipped_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(ws.ws_sales_price) AS average_price
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.customer_category,
    COALESCE(si.total_quantity, 0) AS shipped_quantity,
    COALESCE(si.average_price, 0) AS average_item_price
FROM top_customers tc
LEFT JOIN shipped_items si ON tc.c_customer_sk = CAST(si.ws_item_sk AS INTEGER)
WHERE tc.customer_rank <= 50
ORDER BY tc.total_spent DESC, tc.c_last_name ASC;
