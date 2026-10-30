
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
), high_value_customers AS (
    SELECT
        c_sales.c_customer_id,
        c_sales.total_web_sales,
        c_sales.total_store_sales,
        CASE
            WHEN c_sales.total_web_sales + c_sales.total_store_sales > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM
        customer_sales c_sales
    WHERE
        c_sales.total_web_sales IS NOT NULL OR c_sales.total_store_sales IS NOT NULL
), state_statistics AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT hvc.c_customer_id) AS customer_count,
        AVG(hvc.total_web_sales + hvc.total_store_sales) AS avg_sales
    FROM
        high_value_customers hvc
    JOIN customer_address ca ON hvc.c_customer_id = ca.ca_address_id
    GROUP BY
        ca.ca_state
), promo_sales AS (
    SELECT
        pm.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS promo_total_sales
    FROM
        promotion pm
    JOIN web_sales ws ON pm.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        pm.p_promo_name
)
SELECT
    COALESCE(ss.ca_state, 'Unknown') AS state,
    ss.customer_count,
    ss.avg_sales,
    ps.promo_total_sales,
    COALESCE(ps.promo_total_sales, 0) AS total_sales_with_promotion
FROM
    state_statistics ss
FULL OUTER JOIN promo_sales ps ON ss.customer_count > 0
ORDER BY
    ss.customer_count DESC,
    ps.promo_total_sales DESC;
