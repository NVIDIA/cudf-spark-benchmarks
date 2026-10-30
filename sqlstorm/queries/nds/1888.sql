
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
), TopItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        i.i_product_name,
        i.i_category,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS item_rank
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE sd.rank <= 5
    UNION ALL
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        i.i_product_name,
        i.i_category,
        -1 AS item_rank
    FROM SalesData sd
    LEFT JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE sd.rank IS NULL
), CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM customer_demographics cd
    LEFT JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
), CustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        h.hd_buy_potential,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, h.hd_buy_potential
)
SELECT
    ci.item_rank,
    ci.i_product_name,
    ci.total_quantity,
    ci.total_net_profit,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.hd_buy_potential
FROM TopItems ci
JOIN CustomerData cs ON ci.total_net_profit > cs.total_net_profit
WHERE ci.item_rank >= 0
ORDER BY ci.total_net_profit DESC, cs.total_net_profit DESC;
