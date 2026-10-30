WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ss.ss_net_profit) DESC) AS brand_rank
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price > 0 
        AND i.i_rec_start_date <= cast('2002-10-01' as date) 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
    GROUP BY 
        i.i_item_id, i.i_item_desc, i.i_brand
),
TopSellingItems AS (
    SELECT 
        ri.i_item_id,
        ri.i_item_desc,
        ri.i_brand,
        ri.total_sales_quantity,
        ri.total_net_profit
    FROM 
        RankedItems ri
    WHERE 
        ri.brand_rank <= 5
)
SELECT 
    CONCAT('Brand: ', t.i_brand, ', Item ID: ', t.i_item_id, ', Description: ', t.i_item_desc, ', Quantity Sold: ', CAST(t.total_sales_quantity AS STRING), ', Total Profit: ', CAST(t.total_net_profit AS DECIMAL(10,2))) AS result_summary
FROM 
    TopSellingItems t
ORDER BY 
    t.total_net_profit DESC;