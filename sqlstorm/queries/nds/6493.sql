
WITH sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_item_sk, w.w_warehouse_sk
),
top_selling_items AS (
    SELECT
        sd.ws_item_sk,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        sd.sales_rank
    FROM
        sales_data sd
    JOIN
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE
        sd.sales_rank <= 10
)
SELECT
    tsa.ws_item_sk,
    tsa.i_item_desc,
    tsa.total_quantity,
    tsa.total_sales,
    tsa.order_count,
    cd.cd_gender,
    cd.cd_marital_status
FROM
    top_selling_items tsa
JOIN
    customer_demographics cd ON tsa.ws_item_sk = cd.cd_demo_sk
ORDER BY 
    tsa.total_sales DESC;
