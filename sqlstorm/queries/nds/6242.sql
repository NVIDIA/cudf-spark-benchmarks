
WITH sales_summary AS (
    SELECT
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS net_revenue,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
),
customer_segment AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_quantity) AS total_items_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        cd_gender, cd_marital_status
),
warehouse_details AS (
    SELECT
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_level
    FROM
        warehouse w
    JOIN
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT
    ss.d_year,
    ss.total_sales,
    ss.net_revenue,
    ss.avg_sales_price,
    ss.total_orders,
    ss.unique_customers,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.total_items_sold,
    cs.total_sales_amount,
    wd.w_warehouse_id,
    wd.total_inventory,
    wd.avg_inventory_level
FROM
    sales_summary ss
JOIN
    customer_segment cs ON ss.total_sales > 1000000
JOIN
    warehouse_details wd ON wd.total_inventory > 5000
ORDER BY
    ss.d_year, cs.customer_count DESC;
