
WITH  sales_cte AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        ss_sold_date_sk
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk, ss_sold_date_sk
    HAVING 
        SUM(ss_quantity) > 0
), item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category_id,
        ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY SUM(ss_ext_sales_price) DESC) AS category_rank
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category_id
), customer_preferences AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count,
        MAX(cd.cd_purchase_estimate) AS highest_estimate,
        MIN(cd.cd_dep_count) AS min_dependents
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cdemo.c_customer_sk,
    cdemo.demo_count,
    cdemo.highest_estimate,
    SUM(CASE 
            WHEN id.category_rank <= 5 THEN id.total_sold 
            ELSE 0 
        END) AS top_selling_items,
    COALESCE(SUM(sr.return_qty), 0) AS total_returns
FROM 
    customer_preferences cdemo
LEFT JOIN 
    (SELECT 
        cte.ss_item_sk,
        cte.total_sold,
        item_rank.i_item_id,
        item_rank.i_product_name,
        item_rank.category_rank
     FROM 
        sales_cte cte
     JOIN 
        item_details item_rank ON cte.ss_item_sk = item_rank.i_item_sk
    ) AS id ON cdemo.c_customer_sk = id.ss_item_sk
LEFT JOIN 
    (SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS return_qty
     FROM 
        store_returns
     GROUP BY 
        sr_item_sk
    ) AS sr ON sr.sr_item_sk = id.ss_item_sk
GROUP BY 
    cdemo.c_customer_sk, cdemo.demo_count, cdemo.highest_estimate
ORDER BY 
    cdemo.demo_count DESC, top_selling_items DESC;
