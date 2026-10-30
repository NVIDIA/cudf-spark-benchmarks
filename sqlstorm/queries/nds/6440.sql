
WITH SalesData AS (
    SELECT
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM
        web_sales
    JOIN date_dim d ON d.d_date_sk = ws_sold_date_sk
    WHERE
        d.d_year BETWEEN 2018 AND 2022
    GROUP BY
        d.d_year
),
CustomerData AS (
    SELECT
        cd.cd_gender,
        SUM(sd.total_sales) AS total_sales_by_gender,
        AVG(sd.avg_net_profit) AS avg_net_profit_by_gender,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM
        SalesData sd
    JOIN web_sales ws ON ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year BETWEEN 2018 AND 2022)
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_gender
),
WarehousePerformance AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_revenue,
        AVG(ws_net_profit) AS average_profit
    FROM
        web_sales
    JOIN warehouse w ON w.w_warehouse_sk = ws_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT
    cd.cd_gender,
    cd.total_sales_by_gender,
    cd.avg_net_profit_by_gender,
    cd.unique_customers,
    wp.w_warehouse_id,
    wp.total_orders,
    wp.total_revenue,
    wp.average_profit
FROM
    CustomerData cd
JOIN WarehousePerformance wp ON cd.total_sales_by_gender > wp.total_revenue/1000
ORDER BY
    cd.cd_gender,
    wp.total_revenue DESC;
