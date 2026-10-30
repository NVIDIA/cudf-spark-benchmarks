
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), FilteredItems AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        COALESCE(NULLIF(SUBSTRING(i_item_desc FROM POSITION(' ' IN i_item_desc) FOR 1), ''), 'N/A') AS first_word,
        NULLIF(i_item_desc, '') AS desc_check
    FROM 
        item
    WHERE 
       i_current_price > 0
)
SELECT 
    fi.i_item_sk,
    fi.i_item_desc,
    rs.total_quantity,
    rs.total_net_paid,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Other'
    END AS sales_category
FROM 
    FilteredItems fi
LEFT JOIN 
    RankedSales rs ON fi.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    customer c ON c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F')
WHERE 
    fi.first_word LIKE 'A%'
    AND (rs.total_net_paid IS NULL OR rs.total_net_paid > 100)
    AND (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = fi.i_item_sk AND ss.ss_ext_sales_price > 200) > 5
GROUP BY 
    fi.i_item_sk,
    fi.i_item_desc,
    rs.total_quantity,
    rs.total_net_paid,
    rs.sales_rank
ORDER BY 
    sales_category DESC, total_net_paid DESC
LIMIT 50;
