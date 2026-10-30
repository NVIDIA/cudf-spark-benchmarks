
WITH sales_data AS (
    SELECT
        w.w_warehouse_name,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY
        w.w_warehouse_name, c.c_first_name, c.c_last_name
),
demographic_data AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customers_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    sd.w_warehouse_name,
    sd.c_first_name,
    sd.c_last_name,
    sd.total_sales,
    sd.total_orders,
    sd.avg_profit,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.customers_count,
    dd.avg_purchase_estimate
FROM
    sales_data sd
JOIN
    demographic_data dd ON ROUND(sd.total_sales / NULLIF(dd.avg_purchase_estimate, 0), 2) > 1
ORDER BY
    sd.total_sales DESC, sd.avg_profit ASC
LIMIT 10;
