
WITH RankedSales AS (
    SELECT 
        s.s_store_id,
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_units_sold,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 90
    GROUP BY 
        s.s_store_id, i.i_item_id
), 
TopStores AS (
    SELECT 
        rs.s_store_id,
        SUM(rs.total_sales) AS store_total_sales,
        SUM(rs.total_units_sold) AS store_total_units
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        rs.s_store_id
)
SELECT 
    ts.s_store_id,
    ts.store_total_sales,
    ts.store_total_units,
    ROUND((ts.store_total_sales / COUNT(DISTINCT rs.i_item_id)), 2) AS avg_sales_per_item
FROM 
    TopStores ts
JOIN 
    RankedSales rs ON ts.s_store_id = rs.s_store_id
GROUP BY 
    ts.s_store_id, ts.store_total_sales, ts.store_total_units
ORDER BY 
    ts.store_total_sales DESC;
