
WITH  sales_cte AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
              AND d_month_seq = 1
        )
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        COALESCE(hd.hd_dep_count, 0) AS dependent_count
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
warehouse_info AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY
        w.w_warehouse_sk, w.w_warehouse_name
),
product_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
    HAVING
        SUM(ws.ws_quantity) > 10
)
SELECT
    cd.c_email_address,
    cd.cd_marital_status,
    cd.cd_gender,
    cd.cd_credit_rating,
    pi.total_quantity,
    pi.total_net_profit,
    wi.w_warehouse_name,
    pi.total_quantity * pi.total_net_profit AS net_sales_value,
    CASE 
        WHEN cd.dependent_count > 0 THEN 'Has Dependents'
        WHEN cd.cd_marital_status = 'M' AND cd.cd_gender = 'F' THEN 'Married Female'
        ELSE 'Other'
    END AS customer_category
FROM
    customer_data cd
JOIN product_sales pi ON cd.c_customer_sk = pi.ws_item_sk
JOIN warehouse_info wi ON pi.ws_item_sk = wi.w_warehouse_sk
LEFT JOIN sales_cte sc ON sc.ws_item_sk = pi.ws_item_sk
WHERE
    cd.cd_credit_rating IN ('Good', 'Excellent')
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status IS NULL)
ORDER BY
    net_sales_value DESC
LIMIT 100;
