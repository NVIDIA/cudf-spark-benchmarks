
WITH processed_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        LENGTH(i.i_item_desc) AS desc_length,
        UPPER(i.i_item_desc) AS upper_case_desc,
        LOWER(i.i_item_desc) AS lower_case_desc,
        REPLACE(i.i_item_desc, ' ', '-') AS hyphenated_desc,
        REPLACE(i.i_item_desc, ' ', '_') AS underscored_desc,
        CONCAT(i.i_item_id, ': ', i.i_item_desc) AS concatenated_desc
    FROM item i
),
item_stats AS (
    SELECT 
        desc_length,
        COUNT(*) AS item_count,
        AVG(desc_length) AS avg_length,
        MIN(desc_length) AS min_length,
        MAX(desc_length) AS max_length
    FROM processed_items
    GROUP BY desc_length
),
demographic_analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS max_credit_rating
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_gender
)
SELECT 
    pi.i_item_id,
    pi.i_item_desc,
    pi.desc_length,
    pi.upper_case_desc,
    pi.hyphenated_desc,
    da.customer_count,
    da.avg_purchase_estimate
FROM processed_items pi
JOIN demographic_analysis da ON da.avg_purchase_estimate > 1000
WHERE pi.desc_length BETWEEN 10 AND 100
ORDER BY pi.desc_length DESC, da.customer_count DESC
LIMIT 50;
