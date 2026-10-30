
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        rs.ws_bill_customer_sk, 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_sales,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM ranked_sales rs
    INNER JOIN customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE rs.sales_rank <= 3
),
sales_summary AS (
    SELECT
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ts.ws_item_sk) AS items_bought,
        SUM(ts.total_sales) AS total_spent
    FROM top_sales ts
    INNER JOIN customer c ON ts.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_first_name, c.c_last_name
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.items_bought,
    s.total_spent,
    d.d_date AS date,
    d.d_month_seq,
    d.d_year
FROM sales_summary s
JOIN date_dim d ON d.d_date = DATE '2002-10-01'
ORDER BY s.total_spent DESC
LIMIT 10;
