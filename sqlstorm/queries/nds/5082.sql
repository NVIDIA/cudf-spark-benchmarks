
WITH RankedSales AS (
    SELECT 
        cs.cs_order_number, 
        cs.cs_ship_mode_sk, 
        cs.cs_item_sk, 
        cs.cs_quantity, 
        cs.cs_sales_price, 
        cs.cs_ext_sales_price, 
        ws.ws_sold_date_sk, 
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM 
        catalog_sales cs
    JOIN 
        web_sales ws ON cs.cs_order_number = ws.ws_order_number
    WHERE 
        cs.cs_sold_date_sk BETWEEN 20210101 AND 20211231
), TotalSales AS (
    SELECT 
        RS.cs_ship_mode_sk, 
        SUM(RS.cs_ext_sales_price) AS total_sales
    FROM 
        RankedSales RS
    JOIN 
        ship_mode sm ON RS.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        RS.rn = 1 
    GROUP BY 
        RS.cs_ship_mode_sk
)
SELECT 
    sm.sm_ship_mode_id, 
    sm.sm_type, 
    COALESCE(TS.total_sales, 0) AS total_sales,
    RANK() OVER (ORDER BY COALESCE(TS.total_sales, 0) DESC) AS sales_rank
FROM 
    ship_mode sm
LEFT JOIN 
    TotalSales TS ON sm.sm_ship_mode_sk = TS.cs_ship_mode_sk
ORDER BY 
    sales_rank;
