
WITH CustomerSegment AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        hd_income_band_sk,
        hd_dep_count,
        hd_vehicle_count
    FROM
        customer_demographics AS cd
    JOIN
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales AS ws
    JOIN
        CustomerSegment AS cs ON ws.ws_bill_cdemo_sk = cs.cd_demo_sk
    GROUP BY
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM
        SalesData AS sd
)
SELECT
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_profit,
    ci.i_item_desc,
    ci.i_current_price,
    ci.i_category,
    ci.i_brand
FROM
    TopItems AS ti
JOIN
    item AS ci ON ti.ws_item_sk = ci.i_item_sk
WHERE
    ti.profit_rank <= 10
ORDER BY
    ti.total_profit DESC;
