
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales_price,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit,
        d.d_year,
        p.p_promo_name
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023 
    GROUP BY
        ws_item_sk,
        d.d_year,
        p.p_promo_name
),
top_items AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales_price,
        ss.total_discount,
        ss.total_profit,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_profit DESC) AS rank
    FROM
        sales_summary ss
)
SELECT
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales_price,
    ti.total_discount,
    ti.total_profit,
    d.d_year
FROM
    top_items ti
JOIN
    sales_summary ss ON ti.ws_item_sk = ss.ws_item_sk
JOIN
    date_dim d ON ss.d_year = d.d_year
WHERE
    ti.rank <= 10
ORDER BY
    d.d_year,
    ti.total_profit DESC;
