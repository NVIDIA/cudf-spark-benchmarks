
WITH SalesData AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        store_sales ss
    JOIN
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ss.ss_item_sk
)
SELECT
    item.i_item_id,
    item.i_item_desc,
    sales.total_quantity,
    sales.total_sales,
    sales.total_transactions
FROM
    SalesData sales
JOIN
    item ON sales.ss_item_sk = item.i_item_sk
ORDER BY
    sales.total_sales DESC
LIMIT 10;
