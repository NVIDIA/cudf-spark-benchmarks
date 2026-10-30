
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq IN (6, 7, 8)
        )
    GROUP BY 
        ws_item_sk,
        ws_ship_mode_sk
),
NullHandling AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        COALESCE(r.sales_rank, NULL) AS sales_rank
    FROM 
        RankedSales r
    FULL OUTER JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_item_desc LIKE '%special%' OR r.total_sales IS NULL
),
FinalResults AS (
    SELECT 
        n.ws_item_sk,
        n.total_sales,
        n.sales_rank,
        CASE 
            WHEN n.sales_rank = 1 THEN 'Top Seller'
            WHEN n.sales_rank IS NULL THEN 'No Sales'
            ELSE 'Other'
        END AS sales_category
    FROM 
        NullHandling n
    WHERE 
        n.total_sales > 10000 OR n.sales_rank IS NULL
)
SELECT 
    n.ws_item_sk,
    n.total_sales,
    n.sales_rank,
    n.sales_category,
    d.d_date AS sales_date,
    i.i_item_desc,
    CASE 
        WHEN i.i_brand = 'Gizmo' AND n.sales_category = 'Top Seller' THEN 'VIP Treatment'
        ELSE 'Standard Treatment'
    END AS treatment
FROM 
    FinalResults n
LEFT JOIN 
    item i ON n.ws_item_sk = i.i_item_sk
LEFT JOIN 
    web_sales ws ON n.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
ORDER BY 
    n.total_sales DESC, n.sales_category ASC NULLS LAST;
