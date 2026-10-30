
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY
        d.d_year, d.d_month_seq, w.w_warehouse_name, i.i_item_desc
),
ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
    FROM
        sales_summary
)
SELECT
    rs.d_year,
    rs.d_month_seq,
    rs.w_warehouse_name,
    rs.i_item_desc,
    rs.total_quantity,
    rs.total_net_profit
FROM
    ranked_sales rs
WHERE
    rs.profit_rank <= 5
ORDER BY
    rs.d_year, rs.d_month_seq, rs.total_net_profit DESC;
