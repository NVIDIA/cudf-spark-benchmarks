
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY
        ws.ws_item_sk
),
high_performers AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM
        sales_data sd
    WHERE
        sd.total_quantity > 100
),
avg_sales AS (
    SELECT
        AVG(total_quantity) AS avg_quantity,
        AVG(total_profit) AS avg_profit
    FROM
        sales_data
),
items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM
        item i
    LEFT JOIN household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
    LEFT JOIN customer_demographics cd ON i.i_item_sk = cd.cd_demo_sk
)
SELECT
    i.i_item_sk,
    i.i_item_desc,
    i.buy_potential,
    i.gender,
    i.credit_rating,
    hp.total_quantity,
    hp.total_profit,
    avg.avg_quantity AS overall_avg_quantity,
    avg.avg_profit AS overall_avg_profit
FROM
    items i
JOIN high_performers hp ON i.i_item_sk = hp.ws_item_sk
CROSS JOIN avg_sales avg
ORDER BY
    hp.profit_rank
LIMIT 10;
