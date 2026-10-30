WITH RankedSales AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND 
        dd.d_moy IN (11, 12)  
    GROUP BY 
        ws.ws_web_site_sk, ws.ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(rs.total_sales) AS total_website_sales
    FROM 
        RankedSales rs
    JOIN 
        warehouse w ON rs.ws_web_site_sk = w.w_warehouse_sk
    WHERE 
        rs.sales_rank <= 5  
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name
)
SELECT 
    tw.w_warehouse_id, 
    tw.w_warehouse_name, 
    tw.total_website_sales
FROM 
    TopWebsites tw
ORDER BY 
    tw.total_website_sales DESC;