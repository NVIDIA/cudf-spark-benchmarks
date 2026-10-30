
WITH customer_summary AS (
    SELECT
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        SUM(
            COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)
        ) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM
        customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id, ca.ca_city, ca.ca_state, cd.cd_gender
),
high_value_customers AS (
    SELECT
        cs.c_customer_id,
        cs.ca_city,
        cs.ca_state,
        cs.cd_gender,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM
        customer_summary cs
    WHERE
        cs.total_net_profit > 1000
)
SELECT
    hvc.c_customer_id,
    hvc.ca_city,
    hvc.ca_state,
    hvc.cd_gender,
    hvc.total_net_profit,
    hvc.profit_rank
FROM
    high_value_customers hvc
WHERE
    hvc.profit_rank <= 100
ORDER BY
    hvc.total_net_profit DESC;
