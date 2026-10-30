
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, ca.ca_state
), 
top_customers AS (
    SELECT 
        customer_data.*,
        DENSE_RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM customer_data
)
SELECT 
    t1.ws_item_sk,
    t1.total_quantity,
    t1.total_net_paid,
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.ca_state,
    tc.total_orders
FROM sales_data t1
INNER JOIN top_customers tc ON tc.order_rank <= 10
WHERE t1.total_quantity > (
    SELECT AVG(total_quantity) 
    FROM sales_data 
    WHERE total_quantity IS NOT NULL
)
AND tc.cd_gender IS NOT NULL
ORDER BY t1.total_net_paid DESC
LIMIT 50;
