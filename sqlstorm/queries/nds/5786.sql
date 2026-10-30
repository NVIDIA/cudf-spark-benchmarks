
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_item_id
),
top_items AS (
    SELECT
        d_year,
        d_month_seq,
        i_item_id,
        total_quantity_sold,
        total_net_profit,
        total_sales,
        transaction_count,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
    FROM
        sales_summary
)
SELECT
    d_year,
    d_month_seq,
    i_item_id,
    total_quantity_sold,
    total_net_profit,
    total_sales,
    transaction_count
FROM
    top_items
WHERE
    profit_rank <= 10
ORDER BY
    d_year,
    d_month_seq,
    total_net_profit DESC;
