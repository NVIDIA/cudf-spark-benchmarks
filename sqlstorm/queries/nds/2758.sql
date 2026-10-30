
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
TopSales AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity
    FROM RankedSales rs
    WHERE rs.PriceRank <= 5
),
CustomerStats AS (
    SELECT
        cd.cd_gender,
        SUM(ws.ws_quantity) AS TotalQuantity,
        AVG(ws.ws_sales_price) AS AvgSalesPrice,
        ws.ws_item_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, ws.ws_item_sk
),
InventoryInfo AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS TotalStock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT
    cs.cd_gender,
    COUNT(DISTINCT ts.ws_order_number) AS TotalOrders,
    SUM(ts.ws_quantity) AS TotalItemsSold,
    AVG(ts.ws_sales_price) AS AvgItemPrice,
    ii.TotalStock
FROM TopSales ts
JOIN CustomerStats cs ON ts.ws_item_sk = cs.ws_item_sk
JOIN InventoryInfo ii ON ts.ws_item_sk = ii.inv_item_sk
GROUP BY cs.cd_gender, ii.TotalStock
ORDER BY TotalItemsSold DESC;
