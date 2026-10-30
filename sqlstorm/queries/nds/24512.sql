
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank,
        ws_sold_date_sk,
        ws_ship_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk, ws_ship_date_sk
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales_price,
        ds.d_year,
        COUNT(DISTINCT rs.ws_sold_date_sk) AS sale_days,
        SUM(CASE WHEN rs.sales_rank = 1 THEN rs.total_sales_price ELSE 0 END) AS last_sale_price,
        LAG(rs.total_sales_price) OVER (PARTITION BY rs.ws_item_sk ORDER BY ds.d_year) AS previous_year_sale
    FROM 
        RecursiveSales rs
    JOIN 
        date_dim ds ON rs.ws_sold_date_sk = ds.d_date_sk
    WHERE 
        ds.d_year > 2020
    GROUP BY 
        rs.ws_item_sk, rs.total_sales_price, ds.d_year
),
SalesComparison AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales_price,
        ss.sale_days,
        ss.last_sale_price,
        ss.previous_year_sale,
        CASE 
            WHEN ss.last_sale_price > COALESCE(ss.previous_year_sale, 0) THEN 'Increased'
            WHEN ss.last_sale_price < COALESCE(ss.previous_year_sale, 0) THEN 'Decreased'
            ELSE 'No Change'
        END AS change_status
    FROM 
        SalesSummary ss
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    sc.total_sales_price, 
    sc.sale_days,
    sc.last_sale_price,
    sc.previous_year_sale,
    sc.change_status,
    CONCAT('Item: ', it.i_item_desc, ' has ', sc.change_status) AS status_message
FROM 
    SalesComparison sc
JOIN 
    item it ON sc.ws_item_sk = it.i_item_sk
LEFT JOIN 
    customer_demographics cd ON it.i_item_sk = cd.cd_demo_sk
WHERE 
    (sc.change_status = 'Increased' AND (cd.cd_gender IS NULL OR cd.cd_marital_status = 'S'))
    OR (sc.change_status = 'Decreased' AND cd.cd_dep_count < 2)
ORDER BY 
    sc.total_sales_price DESC, 
    sc.sale_days ASC;
