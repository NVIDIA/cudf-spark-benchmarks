
WITH  SalesTrend AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
),
HighValueCustomers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_purchase_estimate IS NOT NULL AND cd_purchase_estimate > 50000
),
InventoryCheck AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
    HAVING SUM(inv_quantity_on_hand) < 5
),
SalesAndReturns AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_sales,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        SUM(ws_net_paid) - COALESCE(SUM(sr_return_quantity), 0) AS net_sales
    FROM web_sales
    LEFT JOIN store_returns ON ws_item_sk = sr_item_sk AND ws_sold_date_sk = sr_returned_date_sk
    GROUP BY ws_item_sk
)
SELECT
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    st.ws_item_sk,
    st.total_sales,
    iv.total_inventory,
    sar.total_net_sales,
    sar.total_returns,
    sar.net_sales
FROM HighValueCustomers hvc
JOIN SalesTrend st ON hvc.c_customer_sk = st.ws_item_sk
JOIN InventoryCheck iv ON st.ws_item_sk = iv.inv_item_sk
JOIN SalesAndReturns sar ON st.ws_item_sk = sar.ws_item_sk
WHERE hvc.gender_rank <= 10
    AND iv.total_inventory IS NOT NULL
    AND (sar.net_sales IS NULL OR sar.net_sales > 1000)
    OR (hvc.cd_marital_status = 'M' AND hvc.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_marital_status = 'S'))
ORDER BY sar.net_sales DESC, hvc.c_last_name ASC
LIMIT 50;
