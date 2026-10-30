
WITH RecursiveCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ca.ca_address_sk) AS total_addresses,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(DISTINCT ca.ca_address_sk) DESC) AS city_rank
    FROM customer_address AS ca
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM web_sales AS ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory AS inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    rcd.c_first_name,
    rcd.c_last_name,
    rcd.cd_gender,
    cai.ca_city,
    cai.ca_state,
    s.total_net_profit,
    i.total_inventory,
    CASE 
        WHEN s.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_info,
    GREATEST(COALESCE(s.total_net_profit, 0), COALESCE(i.total_inventory, 0)) AS highest_value,
    SUBSTRING(cai.ca_city, 1, 3) || '_' || CAST(t.d_month_seq AS STRING) AS city_month_seq
FROM RecursiveCustomerData AS rcd
LEFT JOIN CustomerAddressInfo AS cai ON rcd.c_customer_sk = cai.total_addresses
LEFT JOIN SalesData AS s ON rcd.c_customer_sk = s.ws_item_sk
FULL OUTER JOIN InventoryData AS i ON s.ws_item_sk = i.inv_item_sk
JOIN date_dim AS t ON t.d_year = 2023 AND t.d_month_seq = 5
WHERE rcd.rn = 1 AND (cai.city_rank IS NULL OR cai.city_rank <= 3)
GROUP BY 
    rcd.c_first_name,
    rcd.c_last_name,
    rcd.cd_gender,
    cai.ca_city,
    cai.ca_state,
    s.total_net_profit,
    i.total_inventory,
    t.d_month_seq
ORDER BY highest_value DESC
LIMIT 100;
