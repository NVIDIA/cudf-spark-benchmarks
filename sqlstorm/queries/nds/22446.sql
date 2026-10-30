
WITH MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM web_sales 
    JOIN date_dim d ON d.d_date_sk = ws_sold_date_sk
    GROUP BY d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    AND (cd.cd_marital_status = 'S' OR cd.cd_marital_status = 'M')
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
InventoryData AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_category
)
SELECT 
    md.d_month_seq,
    cs.cd_gender,
    cs.cd_marital_status,
    md.total_sales,
    cs.customer_count,
    COALESCE(id.total_inventory, 0) AS total_inventory,
    md.total_sales / NULLIF(cs.customer_count, 0) AS average_sales_per_customer,
    md.total_sales / NULLIF(md.order_count, 0) AS average_sales_per_order
FROM MonthlySales md
LEFT JOIN CustomerDemographics cs ON md.d_month_seq % 12 = cs.customer_count % 12
LEFT JOIN InventoryData id ON md.d_month_seq % 10 = id.total_inventory % 10
WHERE 
    (md.total_sales > 10000 OR md.total_sales IS NULL)
    AND (cs.customer_count IS NOT NULL AND cs.customer_count > 1)
ORDER BY md.d_month_seq, cs.cd_gender DESC
LIMIT 100;
