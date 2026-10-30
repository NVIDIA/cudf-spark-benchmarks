
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'No Rating') AS credit_rating,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_paid) DESC) AS state_rank
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, credit_rating, ca.ca_city, ca.ca_state
),
TopSpendingCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM CustomerStats AS cs
    WHERE cs.total_orders > 5 AND cs.total_spent > 1000
),
ProductSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales
    FROM item AS i
    JOIN web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT 
    tsc.c_first_name,
    tsc.c_last_name,
    tsc.total_orders,
    tsc.total_spent,
    ps.i_item_id,
    ps.total_quantity_sold,
    ps.total_sales,
    CASE 
        WHEN ps.total_sales > 5000 THEN 'High Volume'
        WHEN ps.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM TopSpendingCustomers AS tsc
JOIN ProductSales AS ps ON tsc.c_customer_sk IN (
    SELECT ws.ws_bill_customer_sk 
    FROM web_sales AS ws 
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim AS d 
        WHERE d.d_year = 2023 AND d.d_month_seq = 6
    )
)
ORDER BY tsc.total_spent DESC, ps.total_sales DESC;
