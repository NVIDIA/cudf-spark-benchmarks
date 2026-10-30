
WITH  revenue_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_ext_sales_price) > 1000
),
warehouse_inventory AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Female'
        END AS gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS row_num
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_returns AS (
    SELECT
        SUM(sr_return_amt_inc_tax) AS total_returned,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    rev.total_sales,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    COALESCE(ret.total_returned, 0) AS total_returned,
    ci.gender,
    ci.cd_marital_status,
    ci.purchase_estimate
FROM item i
LEFT JOIN revenue_summary rev ON i.i_item_sk = rev.ws_item_sk
LEFT JOIN warehouse_inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN sales_returns ret ON i.i_item_sk = ret.sr_item_sk
LEFT JOIN customer_info ci ON ci.row_num <= 5
WHERE 
    (rev.sales_rank <= 10 OR inv.total_inventory > 50)
    AND ci.purchase_estimate BETWEEN 500 AND 5000
    AND ci.ca_city IS NOT NULL
ORDER BY rev.total_sales DESC, inv.total_inventory ASC;
