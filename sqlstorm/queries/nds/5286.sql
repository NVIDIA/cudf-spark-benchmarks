
WITH SalesData AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_sales_price) AS total_sales_value,
        AVG(ss.ss_net_profit) AS average_net_profit
    FROM
        store_sales ss
    JOIN
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        ss.ss_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3) 
        )
    GROUP BY
        w.w_warehouse_name,
        i.i_category
),
TopSales AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales
    FROM
        store_sales ss
    JOIN
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        w.w_warehouse_name,
        i.i_category
    HAVING
        SUM(ss.ss_quantity) > 1000
)
SELECT
    sd.w_warehouse_name,
    sd.i_category,
    sd.total_quantity_sold,
    sd.total_sales_value,
    sd.average_net_profit,
    ts.total_quantity AS top_category_sales
FROM
    SalesData sd
LEFT JOIN
    TopSales ts ON sd.w_warehouse_name = ts.w_warehouse_name AND sd.i_category = ts.i_category
ORDER BY
    sd.total_sales_value DESC,
    sd.total_quantity_sold DESC;
