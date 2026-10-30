
WITH  Sales_CTE AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM
        web_sales
    WHERE
        ws_net_profit > 0
),
Store_Sales_Summary AS (
    SELECT
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_net_profit
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
Sales_Returns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
Sales_Analysis AS (
    SELECT
        s.s_store_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(sr.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_sales, 0) - COALESCE(sr.total_returns, 0)) AS net_sales
    FROM
        store s
    LEFT JOIN
        Store_Sales_Summary ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN
        Sales_Returns sr ON sr.sr_item_sk IN (SELECT ws_item_sk FROM Sales_CTE WHERE rn <= 10)
),
Gender_Demographics AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(hd_demo_sk) AS avg_income_band
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY
        cd_gender
)
SELECT
    sa.s_store_sk,
    sa.total_sales,
    sa.total_returns,
    sa.net_sales,
    gd.cd_gender,
    gd.customer_count,
    gd.avg_income_band
FROM
    Sales_Analysis sa
JOIN
    Gender_Demographics gd ON sa.s_store_sk = sa.s_store_sk
ORDER BY
    sa.net_sales DESC,
    gd.customer_count DESC
LIMIT 100;
