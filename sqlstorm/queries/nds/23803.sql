WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        CASE 
            WHEN AVG(COALESCE(sst.s_quantity, 0)) = 0 THEN 'No Sales'
            ELSE 'Sales Made'
        END AS sales_status
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk 
    LEFT JOIN 
        (SELECT ss_item_sk, SUM(ss_quantity) AS s_quantity 
         FROM store_sales 
         WHERE ss_sold_date_sk > 20200101 
         GROUP BY ss_item_sk) sst ON ws.ws_item_sk = sst.ss_item_sk
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), FilteredSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        rs.total_sales,
        rs.sales_rank,
        rs.sales_status
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.sales_rank <= 5 AND 
        (rs.sales_status = 'Sales Made' OR rs.total_sales > 200)
), CumulatedSales AS (
    SELECT 
        fs.i_item_id,
        fs.i_product_name,
        fs.total_sales,
        SUM(fs.total_sales) OVER (ORDER BY fs.total_sales DESC) AS cumulative_sales
    FROM 
        FilteredSales fs
)
SELECT 
    cs.i_item_id,
    cs.i_product_name,
    cs.total_sales,
    cs.cumulative_sales,
    CASE 
        WHEN cs.cumulative_sales IS NULL THEN 'Zero Cumulative'
        ELSE 'Cumulative Available'
    END AS cumulative_status
FROM 
    CumulatedSales cs
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.cumulative_sales DESC
LIMIT 50 OFFSET 100;