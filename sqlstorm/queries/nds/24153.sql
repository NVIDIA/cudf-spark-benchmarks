
WITH yearly_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
customer_segment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
return_stats AS (
    SELECT 
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS return_orders
    FROM store_returns
    WHERE sr_return_quantity > 0
),
inventory_levels AS (
    SELECT 
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    ys.d_year,
    cs.cd_gender,
    cs.cd_marital_status,
    ys.total_sales,
    ys.order_count,
    cs.customer_count,
    cs.avg_purchase_estimate,
    rs.total_returns,
    rs.total_return_amount,
    rs.avg_return_quantity,
    ir.avg_inventory,
    CASE 
        WHEN ys.total_sales > 1000000 THEN 'High Sales'
        WHEN ys.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM yearly_sales ys
FULL OUTER JOIN customer_segment cs ON TRUE
FULL OUTER JOIN return_stats rs ON TRUE
LEFT JOIN inventory_levels ir ON ir.inv_item_sk IN (
    SELECT ws.ws_item_sk 
    FROM web_sales ws 
    WHERE ws.ws_net_paid_inc_tax IS NOT NULL
)
WHERE cs.customer_count IS NOT NULL OR rs.total_returns IS NOT NULL
ORDER BY ys.d_year, cs.cd_gender, cs.cd_marital_status;
