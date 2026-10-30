WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    INNER JOIN 
        ship_mode ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    WHERE 
        ws_sold_date_sk BETWEEN 2459007 AND 2459586  
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk
),
MaxSales AS (
    SELECT 
        ws_ship_mode_sk,
        MAX(total_quantity) AS max_quantity,
        MAX(total_sales) AS max_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 5  
    GROUP BY 
        ws_ship_mode_sk
)
SELECT 
    sm.sm_ship_mode_id,
    ms.max_quantity,
    ms.max_sales,
    'Top Performers' AS category
FROM 
    MaxSales ms
JOIN 
    ship_mode sm ON ms.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    RankedSales rs ON ms.ws_ship_mode_sk = rs.ws_ship_mode_sk AND rs.total_quantity = ms.max_quantity
ORDER BY 
    sm.sm_ship_mode_id;