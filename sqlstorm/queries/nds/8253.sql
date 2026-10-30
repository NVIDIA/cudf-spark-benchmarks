WITH sales_summary AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        AVG(ws.ws_net_profit) AS average_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2001 AND
        dd.d_month_seq IN (1, 2, 3) 
    GROUP BY
        i.i_item_sk, i.i_item_id, i.i_item_desc
),
top_sales AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity_sold,
    ts.total_sales_amount,
    ts.total_discount_amount,
    ts.average_net_profit,
    ts.total_orders
FROM
    top_sales ts
WHERE
    ts.sales_rank <= 10
ORDER BY
    ts.total_sales_amount DESC;