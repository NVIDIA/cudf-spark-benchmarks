
WITH SalesData AS (
    SELECT
        s.ss_store_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS order_count,
        AVG(s.ss_net_profit) AS avg_net_profit
    FROM
        store_sales s
    JOIN
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY
        s.ss_store_sk,
        s.ss_item_sk
),
RankedSales AS (
    SELECT
        sd.ss_store_sk,
        sd.ss_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        sd.avg_net_profit,
        RANK() OVER (PARTITION BY sd.ss_store_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
)
SELECT
    ws.w_warehouse_id,
    rs.ss_store_sk,
    rs.ss_item_sk,
    rs.total_quantity,
    rs.total_sales,
    rs.order_count,
    rs.avg_net_profit,
    CASE
        WHEN rs.sales_rank <= 10 THEN 'Top 10 Products'
        ELSE 'Other Products'
    END AS product_category
FROM
    RankedSales rs
JOIN
    warehouse ws ON rs.ss_store_sk = ws.w_warehouse_sk
WHERE
    rs.sales_rank <= 10
ORDER BY
    ws.w_warehouse_id,
    rs.total_sales DESC;
