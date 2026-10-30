
WITH ItemStats AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(ss.ss_net_profit) AS average_net_profit
    FROM
        item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price
),
TopItems AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        ItemStats
)
SELECT
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.average_net_profit,
    d.d_month_seq,
    d.d_year,
    w.w_warehouse_name,
    sm.sm_carrier
FROM
    TopItems ti
JOIN inventory inv ON ti.i_item_sk = inv.inv_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
JOIN ship_mode sm ON inv.inv_warehouse_sk = sm.sm_ship_mode_sk
WHERE
    ti.sales_rank <= 10 
    AND w.w_state = 'CA'
ORDER BY
    ti.total_sales DESC;
