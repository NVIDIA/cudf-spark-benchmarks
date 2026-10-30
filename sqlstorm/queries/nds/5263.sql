
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
),
top_items AS (
    SELECT
        ris.ws_item_sk,
        SUM(ris.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ris.ws_order_number) AS total_orders
    FROM
        ranked_sales ris
    WHERE
        ris.profit_rank <= 5
    GROUP BY
        ris.ws_item_sk
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        SUM(ti.total_profit) AS gender_total_profit,
        AVG(ti.total_orders) AS avg_orders_per_item
    FROM
        top_items ti
    JOIN
        customer c ON ti.ws_item_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
)
SELECT 
    da.cd_gender,
    da.gender_total_profit,
    da.avg_orders_per_item
FROM
    demographic_analysis da
ORDER BY
    da.gender_total_profit DESC;
