
WITH RankedProducts AS (
    SELECT 
        i.i_item_id,
        LOWER(i.i_item_desc) AS item_description,
        LENGTH(i.i_item_desc) AS desc_length,
        i.i_current_price,
        RANK() OVER (PARTITION BY SUBSTRING(i.i_item_desc FROM 1 FOR 10) ORDER BY LENGTH(i.i_item_desc) DESC) AS desc_rank
    FROM 
        item i
    WHERE 
        i.i_item_desc IS NOT NULL
),
FilteredProducts AS (
    SELECT 
        rp.i_item_id,
        rp.item_description,
        rp.desc_length,
        rp.i_current_price
    FROM 
        RankedProducts rp
    WHERE 
        rp.desc_rank = 1
)
SELECT 
    fp.i_item_id,
    fp.item_description,
    fp.desc_length,
    fp.i_current_price,
    CASE 
        WHEN fp.i_current_price < 10 THEN 'Low' 
        WHEN fp.i_current_price BETWEEN 10 AND 50 THEN 'Medium' 
        ELSE 'High' 
    END AS price_band
FROM 
    FilteredProducts fp
ORDER BY 
    fp.desc_length DESC, fp.i_current_price ASC
LIMIT 100;
