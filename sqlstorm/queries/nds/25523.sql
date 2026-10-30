
WITH BaseData AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        CONCAT(c.c_first_name, ' ', c.c_last_name) LIKE '%John%' 
        OR ca.ca_city LIKE '%Springfield%'
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
),
RankedData AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_profit DESC) AS profit_rank
    FROM
        BaseData
)
SELECT
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_profit
FROM
    RankedData
WHERE
    profit_rank <= 5
ORDER BY
    ca_state,
    total_profit DESC;
