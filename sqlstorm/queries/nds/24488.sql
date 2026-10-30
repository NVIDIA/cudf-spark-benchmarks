
WITH  sales_data AS (
    SELECT 
        ss_item_sk,
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk, ss_store_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown' 
            ELSE CAST(cd.cd_dep_count AS STRING) 
        END AS dependent_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_credit_rating DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price, 
        ci.total_income_band,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Not Priced' 
            ELSE 
                CASE 
                    WHEN i.i_current_price < 10 THEN 'Cheap'
                    WHEN i.i_current_price BETWEEN 10 AND 50 THEN 'Moderate'
                    ELSE 'Expensive' 
                END 
        END AS price_category
    FROM 
        item i 
    LEFT JOIN (
        SELECT 
            COUNT(DISTINCT hd_demo_sk) AS total_income_band, 
            ib.ib_income_band_sk
        FROM 
            household_demographics hd 
        JOIN 
            income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY 
            ib.ib_income_band_sk
    ) ci ON i.i_item_sk = ci.ib_income_band_sk
),
final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_quantity,
        ss.total_net_paid,
        ii.i_item_desc,
        ii.price_category
    FROM 
        customer_stats cs
    LEFT JOIN 
        sales_data ss ON cs.c_customer_sk = ss.ss_item_sk
    LEFT JOIN 
        item_info ii ON ss.ss_item_sk = ii.i_item_sk
)
SELECT 
    DISTINCT fr.c_customer_sk,
    CONCAT(fr.c_first_name, ' ', fr.c_last_name) AS full_name,
    fr.total_quantity,
    fr.total_net_paid,
    COALESCE(fr.i_item_desc, 'No Item Sold') AS item_description,
    CASE 
        WHEN fr.price_category IS NOT NULL THEN fr.price_category 
        ELSE 'No Price Available' 
    END AS price_category
FROM 
    final_report fr
WHERE 
    fr.total_quantity IS NOT NULL
    AND fr.total_net_paid > 0
ORDER BY 
    fr.total_net_paid DESC,
    fr.c_customer_sk
LIMIT 100;
