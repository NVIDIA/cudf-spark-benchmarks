
WITH total_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_price,
        SUM(ws_coupon_amt) AS total_coupons,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY
        ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_buy_potential
),
top_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales_price DESC) AS sales_rank
    FROM
        item i
    JOIN
        total_sales ts ON i.i_item_sk = ts.ws_item_sk
    WHERE
        ts.total_sales_price > 1000
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.buy_potential,
    ti.i_item_desc,
    ti.sales_rank,
    COALESCE(ts.total_sales_price, 0) AS total_sales,
    COALESCE(ts.total_coupons, 0) AS total_coupons,
    ci.total_web_orders
FROM
    customer_info ci
LEFT JOIN
    top_items ti ON ci.total_web_orders > 10 AND ti.sales_rank <= 5
LEFT JOIN
    total_sales ts ON ti.i_item_sk = ts.ws_item_sk
WHERE
    ci.total_web_orders IS NOT NULL
ORDER BY
    ci.c_last_name, ci.c_first_name;
