
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ws.ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank = 1
        AND sd.total_sales > 1000
        OR EXISTS (
            SELECT 1
            FROM store_sales ss
            WHERE ss.ss_item_sk = sd.ws_item_sk
            AND ss.ss_sales_price > 500
        )
),
ShippingCosts AS (
    SELECT 
        ws.ws_item_sk,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
FinalReport AS (
    SELECT 
        f.ws_item_sk,
        f.total_quantity,
        f.total_sales - f.total_discount AS net_sales,
        f.total_profit,
        s.avg_ship_cost,
        CASE 
            WHEN f.total_quantity = 0 THEN NULL 
            ELSE f.total_sales / f.total_quantity 
        END AS avg_sales_price
    FROM 
        FilteredSales f
    LEFT JOIN 
        ShippingCosts s ON f.ws_item_sk = s.ws_item_sk
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.net_sales,
    fr.total_profit,
    fr.avg_ship_cost,
    COALESCE(fr.avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN fr.avg_sales_price IS NULL THEN 'No Sales'
        WHEN fr.total_profit > 5000 THEN 'High Profit'
        WHEN fr.total_profit IS NULL THEN 'Unknown Profit'
        ELSE 'Normal Profit'
    END AS profit_category
FROM 
    FinalReport fr
WHERE 
    fr.net_sales IS NOT NULL 
    AND (fr.avg_ship_cost IS NOT NULL OR fr.total_quantity > 0)
ORDER BY 
    fr.net_sales DESC, 
    profit_category;
