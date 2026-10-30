
WITH sales_data AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        store_sales ss
    JOIN
        item i ON ss.ss_item_sk = i.i_item_sk
    JOIN
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        w.w_warehouse_id, i.i_item_id
),
customer_data AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 500
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
ranked_sales AS (
    SELECT
        sd.w_warehouse_id,
        sd.i_item_id,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.total_transactions,
        ROW_NUMBER() OVER (PARTITION BY sd.w_warehouse_id ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        sales_data sd
)
SELECT
    rs.w_warehouse_id,
    rs.i_item_id,
    rs.total_quantity_sold,
    rs.total_sales,
    rs.total_transactions,
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.total_spent
FROM
    ranked_sales rs
JOIN
    customer_data cd ON rs.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w WHERE w.w_warehouse_sk = (SELECT MIN(w_warehouse_sk) FROM warehouse))
WHERE
    rs.sales_rank <= 5
ORDER BY
    rs.w_warehouse_id, rs.total_sales DESC;
