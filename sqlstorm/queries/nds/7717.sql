
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        dd.d_year = 2023
        AND i.i_current_price > 0
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        ws.ws_item_sk
),
top_sales AS (
    SELECT
        ss.ws_item_sk,
        i.i_product_name,
        ss.total_quantity_sold,
        ss.total_sales_amount,
        ss.total_discount_amount,
        ss.avg_net_profit,
        ss.total_orders,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales_amount DESC) AS sales_rank
    FROM
        sales_summary ss
    JOIN
        item i ON ss.ws_item_sk = i.i_item_sk
)
SELECT
    ts.sales_rank,
    ts.i_product_name,
    ts.total_quantity_sold,
    ts.total_sales_amount,
    ts.total_discount_amount,
    ts.avg_net_profit,
    ts.total_orders
FROM
    top_sales ts
WHERE
    ts.sales_rank <= 10
ORDER BY
    ts.sales_rank;
