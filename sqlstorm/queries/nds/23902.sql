
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
    GROUP BY 
        ws.ws_item_sk
), HighSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        rs.order_count,
        CASE 
            WHEN rs.order_count > 100 THEN 'High'
            WHEN rs.order_count BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
), StoreDetails AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        SUM(ss.ss_net_paid) AS store_net_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    sd.s_store_name,
    sd.store_net_sales,
    hs.ws_item_sk,
    hs.total_sales,
    hs.sales_category
FROM 
    HighSales hs
JOIN 
    StoreDetails sd ON hs.ws_item_sk IN (SELECT i.i_item_sk 
                                          FROM item i 
                                          WHERE i.i_current_price IS NOT NULL 
                                          AND i.i_current_price > 0)
WHERE 
    sd.store_net_sales > (SELECT AVG(store_net_sales) 
                           FROM StoreDetails) AND
    hs.total_sales IS NOT NULL
ORDER BY 
    sd.store_net_sales DESC,
    hs.total_sales DESC
LIMIT 25;
