WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
high_sales_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        i.i_item_desc,
        i.i_current_price,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ss.total_sales DESC) AS gender_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = i.i_item_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    hsi.ws_item_sk,
    hsi.total_quantity,
    hsi.total_sales,
    hsi.i_item_desc,
    hsi.i_current_price,
    hsi.cd_gender,
    CASE 
        WHEN hsi.total_sales > 10000 THEN 'High Sales'
        WHEN hsi.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    high_sales_items hsi
WHERE 
    hsi.gender_rank <= 5
ORDER BY 
    hsi.total_sales DESC;