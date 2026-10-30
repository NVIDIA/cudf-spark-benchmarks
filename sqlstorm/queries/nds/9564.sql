
WITH sold_items AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM
        item i
),
popular_items AS (
    SELECT
        id.i_item_sk,
        id.i_item_desc,
        id.i_brand,
        id.i_category,
        id.i_current_price,
        si.total_quantity,
        si.total_sales,
        si.total_coupons,
        si.total_profit
    FROM
        item_details id
    JOIN
        sold_items si ON id.i_item_sk = si.ws_item_sk
    ORDER BY
        si.total_quantity DESC
    LIMIT 10
),
customer_profiles AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(si.total_sales) AS total_spending
    FROM
        customer_demographics cd
    JOIN
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    JOIN
        sold_items si ON ws.ws_item_sk = si.ws_item_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT
        cp.cd_demo_sk,
        cp.cd_gender,
        cp.cd_marital_status,
        cp.total_spending
    FROM
        customer_profiles cp
    ORDER BY
        cp.total_spending DESC
    LIMIT 5
)
SELECT
    ti.i_item_desc,
    ti.i_brand,
    ti.i_category,
    ti.i_current_price,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_spending
FROM
    popular_items ti
JOIN
    top_customers tc ON ti.total_profit > (SELECT AVG(total_profit) FROM sold_items);
