WITH sales_data AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_list_price) AS avg_list_price,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY
        cs.cs_item_sk
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
warehouse_data AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_sk, w.w_warehouse_name
),
performance_benchmark AS (
    SELECT
        sd.cs_item_sk,
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        wd.w_warehouse_name,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_list_price,
        sd.avg_sales_price,
        sd.order_count,
        wd.total_web_orders,
        wd.total_net_profit
    FROM
        sales_data sd
    JOIN
        customer_details cd ON sd.cs_item_sk = cd.hd_income_band_sk 
    JOIN
        warehouse_data wd ON cd.hd_income_band_sk = wd.w_warehouse_sk 
)
SELECT
    *,
    RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_net_profit DESC) AS rank_by_profit
FROM
    performance_benchmark
WHERE
    total_sales > 1000 AND order_count > 5
ORDER BY
    w_warehouse_name, total_net_profit DESC;