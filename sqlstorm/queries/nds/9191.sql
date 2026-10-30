
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY cs_item_sk
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
SalesSummary AS (
    SELECT 
        s.cs_item_sk,
        s.total_quantity,
        s.total_sales,
        s.total_discount,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_credit_rating,
        i.total_inventory
    FROM SalesData s
    JOIN CustomerData c ON s.cs_item_sk = c.c_customer_sk
    JOIN InventoryData i ON s.cs_item_sk = i.inv_item_sk
)
SELECT 
    *,
    (total_sales - total_discount) AS net_sales,
    (total_quantity / NULLIF(total_inventory, 0)) AS inventory_turnover
FROM SalesSummary
ORDER BY net_sales DESC
LIMIT 100;
