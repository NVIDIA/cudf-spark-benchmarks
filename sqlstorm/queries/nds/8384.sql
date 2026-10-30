
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        i_category,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        ws_sold_date_sk, i_category
),
DateInfo AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM
        date_dim d
),
Summary AS (
    SELECT
        di.d_year,
        di.d_month_seq,
        di.d_week_seq,
        sd.i_category,
        sd.total_quantity,
        sd.total_net_profit,
        sd.order_count
    FROM
        SalesData sd
    JOIN
        DateInfo di ON sd.ws_sold_date_sk = di.d_date_sk
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.d_week_seq,
    s.i_category,
    s.total_quantity,
    s.total_net_profit,
    s.order_count,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_net_profit DESC) AS profit_rank
FROM
    Summary s
ORDER BY
    s.d_year, profit_rank
LIMIT 10;
