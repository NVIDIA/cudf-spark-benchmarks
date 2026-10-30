
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
        )
),
customer_stats AS (
    SELECT
        ca.ca_address_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        ca.ca_address_sk,
        cd.cd_gender
),
sales_summary AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        item
    JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY
        item.i_item_id,
        item.i_item_desc
)
SELECT
    cs.ca_address_sk,
    cs.cd_gender,
    cs.customer_count,
    cs.total_spent,
    ss.total_sales,
    ss.order_count,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Spending'
        WHEN cs.total_spent < 100 THEN 'Low Spender'
        WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Moderate Spender'
        ELSE 'High Spender'
    END AS spending_category,
    COALESCE(ranked_sales.ws_quantity, 0) AS top_item_quantity,
    COALESCE(ranked_sales.ws_net_paid, 0) AS top_item_revenue
FROM
    customer_stats cs
LEFT JOIN sales_summary ss ON cs.total_spent = ss.total_sales
LEFT JOIN ranked_sales ON ranked_sales.sales_rank = 1
WHERE
    cs.customer_count > 0
ORDER BY 
    cs.total_spent DESC, ss.total_sales ASC;
