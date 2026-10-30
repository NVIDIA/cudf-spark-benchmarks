
WITH customer_data AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS average_transaction_value,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
warehouse_data AS (
    SELECT
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        warehouse w
    JOIN
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY
        w.w_warehouse_id
), 
sales_data AS (
    SELECT
        date_dim.d_year,
        SUM(ws.ws_net_profit) AS total_sales
    FROM
        web_sales ws
    JOIN
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY
        date_dim.d_year
)
SELECT
    cd.c_customer_id,
    cd.total_net_profit,
    cd.total_orders,
    cd.average_transaction_value,
    cd.unique_items_purchased,
    wd.w_warehouse_id,
    wd.total_inventory,
    sd.d_year,
    sd.total_sales
FROM
    customer_data cd
JOIN
    warehouse_data wd ON TRUE  
JOIN
    sales_data sd ON TRUE  
ORDER BY
    cd.total_net_profit DESC,
    sd.total_sales DESC
LIMIT 100;
