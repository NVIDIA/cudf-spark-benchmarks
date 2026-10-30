
WITH  sales_history AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= 100 AND ws_sold_date_sk <= 200
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
ranked_customers AS (
    SELECT
        c.*,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rnk
    FROM customer_info c
    WHERE total_orders > 5
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_orders,
    rc.total_spent,
    a.ca_city,
    a.ca_state,
    a.customer_count,
    (SELECT AVG(ws_net_paid) FROM web_sales WHERE ws_quantity > 10) AS average_high_value_sales
FROM ranked_customers rc
LEFT JOIN address_info a ON a.customer_count > 10
WHERE rc.rnk <= 10
    AND (rc.cd_marital_status = 'M' OR rc.cd_marital_status IS NULL)
ORDER BY rc.total_spent DESC, rc.c_last_name ASC;
