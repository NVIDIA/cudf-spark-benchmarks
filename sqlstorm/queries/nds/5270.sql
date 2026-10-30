
WITH SalesData AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        cd.cd_marital_status = 'M'
        AND d.d_year BETWEEN 2022 AND 2023
        AND i.i_category = 'Electronics'
    GROUP BY
        d.d_year, d.d_month_seq, d.d_week_seq
),
RankingData AS (
    SELECT
        d_year,
        d_month_seq,
        d_week_seq,
        total_sales,
        total_quantity,
        order_count,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesData
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.d_week_seq,
    r.total_sales,
    r.total_quantity,
    r.order_count,
    r.sales_rank
FROM
    RankingData r
WHERE
    r.sales_rank <= 10
ORDER BY
    r.d_year, r.sales_rank;
