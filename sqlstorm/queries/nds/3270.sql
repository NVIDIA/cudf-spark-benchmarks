
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_sales, 0) AS total_sales
    FROM 
        item i
    LEFT JOIN 
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_dep_count AS STRING)
        END AS dependent_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    id.i_item_id,
    SUM(id.total_quantity) AS total_sold,
    AVG(id.total_sales) AS avg_sales,
    cd.cd_gender,
    cd.dependent_count
FROM 
    item_sales id
JOIN 
    customer_data cd ON cd.hd_income_band_sk IS NOT NULL
JOIN 
    web_sales ws ON id.i_item_sk = ws.ws_item_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND id.total_sales > (SELECT AVG(total_sales) FROM item_sales)
GROUP BY 
    id.i_item_id, cd.cd_gender, cd.dependent_count
HAVING 
    SUM(id.total_quantity) > 10
ORDER BY 
    total_sold DESC;
