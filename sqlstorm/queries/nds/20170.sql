
WITH cte_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
cte_customer AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE 
                CASE 
                    WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
                    WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
                    ELSE 'High'
                END
        END AS purchase_band
    FROM
        customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year IS NOT NULL AND
        (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
),
cte_inventory AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM
        inventory
    GROUP BY
        inv_item_sk
),
cte_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        COUNT(DISTINCT s.s_store_sk) AS store_count
    FROM
        warehouse w
    JOIN store s ON w.w_warehouse_sk = s.s_company_id
    GROUP BY
        w.w_warehouse_sk
)
SELECT
    it.i_item_id,
    it.i_item_desc,
    COALESCE(cs.total_quantity, 0) AS web_total_sales,
    COALESCE(cs.total_net_profit, 0) AS web_total_net_profit,
    COALESCE(ci.total_inventory, 0) AS total_inventory,
    w.store_count,
    cu.purchase_band,
    CASE
        WHEN cu.purchase_band = 'Unknown' AND COALESCE(cs.total_net_profit, 0) > 1000 THEN 'High Value Unknown'
        WHEN cu.purchase_band = 'Low' AND COALESCE(cs.total_net_profit, 0) <= 1000 THEN 'Low Value Low Purchase'
        ELSE 'General'
    END AS customer_value_category
FROM
    item it
LEFT JOIN cte_sales cs ON it.i_item_sk = cs.ws_item_sk
LEFT JOIN cte_inventory ci ON it.i_item_sk = ci.inv_item_sk
LEFT JOIN cte_warehouse w ON w.w_warehouse_sk = it.i_manufact_id
LEFT JOIN cte_customer cu ON cu.c_customer_sk = (
    SELECT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_current_addr_sk IS NOT NULL 
    LIMIT 1
) 
WHERE
    (COALESCE(ci.total_inventory, 0) <= 10 OR cs.total_quantity IS NULL)
    AND (cu.purchase_band = 'Low' OR cu.purchase_band IS NULL)
ORDER BY
    web_total_sales DESC
LIMIT 50;
