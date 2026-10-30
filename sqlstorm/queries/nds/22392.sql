
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        cs_item_sk
),
RankedSales AS (
    SELECT 
        item.i_item_id,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_sales, 0) AS total_sales,
        RANK() OVER (ORDER BY COALESCE(s.total_sales, 0) DESC) AS sales_rank
    FROM 
        item
    LEFT JOIN 
        (SELECT 
            ws_item_sk, total_quantity, total_sales 
         FROM 
            SalesCTE) AS s
    ON 
        item.i_item_sk = s.ws_item_sk
)
SELECT 
    r.i_item_id AS item_id,
    r.total_quantity,
    r.total_sales,
    r.sales_rank,
    (SELECT COUNT(DISTINCT c_customer_id) 
     FROM customer 
     WHERE c_current_cdemo_sk IS NOT NULL) AS total_customers,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Sales'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    (SELECT 
        AVG(sm.sm_ship_mode_sk) 
     FROM 
        ship_mode sm 
     LEFT JOIN 
        store_sales ss ON sm.sm_ship_mode_sk = ss.ss_sold_date_sk 
     WHERE 
        ss.ss_net_paid IS NOT NULL) AS avg_ship_mode
FROM 
    RankedSales r
WHERE 
    r.total_sales IS NOT NULL
    AND r.sales_rank < 10
ORDER BY 
    r.sales_rank, r.total_sales DESC;
