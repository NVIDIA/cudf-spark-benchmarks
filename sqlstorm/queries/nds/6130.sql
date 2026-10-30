
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        ds.d_year
    FROM
        web_sales ws
    JOIN
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    WHERE
        ds.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.ws_sold_date_sk, ds.d_year
),
TopProfit AS (
    SELECT
        sd.d_year,
        sd.total_net_profit,
        sd.total_orders,
        sd.avg_net_paid,
        RANK() OVER (PARTITION BY sd.d_year ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM
        SalesData sd
)
SELECT
    tp.d_year,
    tp.total_net_profit,
    tp.total_orders,
    tp.avg_net_paid
FROM
    TopProfit tp
WHERE
    tp.profit_rank <= 10
ORDER BY
    tp.d_year, tp.total_net_profit DESC;
