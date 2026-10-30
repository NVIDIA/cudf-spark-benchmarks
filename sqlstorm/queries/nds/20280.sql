
WITH AddressData AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM customer_address
    GROUP BY ca_city, ca_state
), 
DemographicData AS (
    SELECT 
        cd_marital_status, 
        cd_gender, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
    GROUP BY cd_marital_status, cd_gender
),
DateData AS (
    SELECT 
        d_year, 
        COUNT(*) AS total_days, 
        SUM(CASE WHEN d_current_month = 'Y' AND d_current_year = 'Y' THEN 1 ELSE 0 END) AS current_month_days
    FROM date_dim
    GROUP BY d_year
),
SalesData AS (
    SELECT 
        SUM(ws_net_profit) AS total_profit, 
        ws_ship_mode_sk,
        DENSE_RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_ship_mode_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    WHERE inv_quantity_on_hand IS NOT NULL
    GROUP BY inv_item_sk
),
FinalData AS (
    SELECT 
        ad.ca_city, 
        ad.ca_state, 
        dd.cd_marital_status, 
        dd.cd_gender, 
        dd.avg_purchase_estimate, 
        sd.total_profit,
        COALESCE(id.total_inventory, 0) AS inventory_count,
        dd.avg_purchase_estimate * COALESCE(id.total_inventory, 0) AS estimated_sales_potential
    FROM AddressData ad
    JOIN DemographicData dd ON ad.address_count > 10
    LEFT JOIN SalesData sd ON sd.profit_rank = 1
    LEFT JOIN InventoryData id ON dd.avg_purchase_estimate > 100
    WHERE 
        (ad.ca_state IN ('NY', 'CA') OR dd.cd_gender IS NULL)
        AND (COALESCE(sd.total_profit, 0) > 1000 OR dd.cd_marital_status = 'S')
)
SELECT 
    ca_city,
    ca_state,
    cd_marital_status, 
    cd_gender, 
    avg_purchase_estimate, 
    total_profit, 
    inventory_count, 
    estimated_sales_potential
FROM FinalData
WHERE estimated_sales_potential IS NOT NULL
ORDER BY estimated_sales_potential DESC
LIMIT 100;
