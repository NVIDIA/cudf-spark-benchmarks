
WITH CustomerGenderCount AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics 
    INNER JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
ItemPromotionCount AS (
    SELECT 
        i_brand,
        COUNT(DISTINCT p_promo_id) AS promo_count
    FROM 
        item
    LEFT JOIN 
        promotion ON i_item_sk = p_item_sk
    GROUP BY 
        i_brand
),
CombinedData AS (
    SELECT 
        c.cd_gender,
        c.customer_count,
        i.i_brand AS item_brand,
        i.promo_count
    FROM 
        CustomerGenderCount AS c
    JOIN 
        ItemPromotionCount AS i ON c.cd_gender = (CASE WHEN i.i_brand IS NOT NULL THEN c.cd_gender ELSE 'Unknown' END)
)
SELECT 
    cd_gender,
    SUM(customer_count) AS total_customers,
    AVG(promo_count) AS average_promotions
FROM 
    CombinedData
GROUP BY 
    cd_gender;
