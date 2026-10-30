
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
    GROUP BY 
        ws.ws_item_sk
),
InventoryData AS (
    SELECT 
        i.inv_item_sk,
        i.inv_quantity_on_hand
    FROM 
        inventory i
    WHERE 
        i.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),
CombinedData AS (
    SELECT 
        s.ws_item_sk,
        s.total_sold,
        s.total_profit,
        i.inv_quantity_on_hand,
        s.max_sales_price,
        s.min_sales_price,
        s.avg_sales_price
    FROM 
        SalesData s
    LEFT JOIN 
        InventoryData i ON s.ws_item_sk = i.inv_item_sk
),
RankedData AS (
    SELECT 
        cd.*,
        RANK() OVER (PARTITION BY CASE WHEN total_profit > 1000 THEN 'High Profit' ELSE 'Low Profit' END ORDER BY total_profit DESC) AS profit_rank
    FROM 
        CombinedData cd
)
SELECT 
    c.c_customer_id,
    COALESCE(SUM(rd.total_sold), 0) AS total_units_sold,
    COUNT(DISTINCT rd.ws_item_sk) AS total_unique_items_sold,
    MAX(rd.avg_sales_price) AS max_average_sales_price,
    NULLIF(AVG(rd.total_profit), 0) AS average_profit_per_sale,
    CASE 
        WHEN SUM(rd.total_sold) IS NULL THEN 'No Sales'
        WHEN SUM(rd.total_sold) < 100 THEN 'Low Sales'
        ELSE 'Good Sales'
    END AS sales_status
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    RankedData rd ON ws.ws_item_sk = rd.ws_item_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_customer_id
HAVING 
    COUNT(DISTINCT rd.ws_item_sk) > 1
ORDER BY 
    sales_status, total_units_sold DESC;
