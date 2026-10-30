
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS rn
    FROM
        SalesData sd
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(ts.total_quantity) AS quantity_sold,
    SUM(ts.total_profit) AS total_revenue,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM
    TopSales ts
JOIN
    item i ON ts.ws_item_sk = i.i_item_sk
LEFT JOIN
    customer c ON c.c_current_hdemo_sk IN (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_income_band_sk IN (
            SELECT ib_income_band_sk
            FROM income_band
            WHERE ib_lower_bound BETWEEN 20000 AND 50000
        )
    )
LEFT JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ts.rn = 1
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    SUM(ts.total_profit) > 10000
ORDER BY
    total_revenue DESC;
