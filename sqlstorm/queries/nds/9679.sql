
WITH customer_stats AS (
    SELECT
        ca.ca_country,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
    GROUP BY
        ca.ca_country,
        cd.cd_gender
),
warehouse_sales AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT
    cs.ca_country,
    cs.cd_gender,
    cs.total_quantity,
    cs.total_sales,
    cs.avg_profit,
    ws.w_warehouse_id,
    ws.quantity_sold,
    ws.total_revenue
FROM
    customer_stats cs
JOIN
    warehouse_sales ws ON cs.total_quantity > 100
ORDER BY
    cs.total_sales DESC,
    ws.total_revenue DESC
LIMIT 100;
