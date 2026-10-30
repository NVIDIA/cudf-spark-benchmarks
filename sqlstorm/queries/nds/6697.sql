
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        d_year,
        d_month_seq,
        d_dow
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
),
AggregatedSales AS (
    SELECT
        d_month_seq,
        d_dow,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold,
        SUM(ws_quantity) AS total_quantity_sold
    FROM
        SalesData
    GROUP BY
        d_month_seq, d_dow
),
RankedSales AS (
    SELECT
        d_month_seq,
        d_dow,
        total_net_paid,
        unique_items_sold,
        total_quantity_sold,
        RANK() OVER (PARTITION BY d_month_seq ORDER BY total_net_paid DESC) AS net_paid_rank,
        RANK() OVER (PARTITION BY d_month_seq ORDER BY unique_items_sold DESC) AS unique_items_rank
    FROM
        AggregatedSales
)
SELECT
    d_month_seq,
    d_dow,
    total_net_paid,
    unique_items_sold,
    total_quantity_sold,
    net_paid_rank,
    unique_items_rank
FROM
    RankedSales
WHERE
    net_paid_rank <= 5 OR unique_items_rank <= 5
ORDER BY
    d_month_seq, net_paid_rank, unique_items_rank;
