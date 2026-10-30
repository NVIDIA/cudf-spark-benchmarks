
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CTE_Item_Sales AS (
    SELECT 
        ws.ws_item_sk AS item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk
),
CTE_Seasonal_Sales AS (
    SELECT 
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales_catalog,
        SUM(ws.ws_ext_sales_price) AS total_sales_web,
        COUNT(DISTINCT cs.cs_order_number) AS count_catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS count_web_orders
    FROM 
        date_dim d
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_month_seq
)
SELECT 
    cs.customer_id, 
    cs.total_sales,
    cs.total_orders,
    i.item_id, 
    i.total_quantity_sold,
    i.total_net_profit,
    ss.d_month_seq,
    ss.total_sales_catalog,
    ss.total_sales_web,
    ss.count_catalog_orders,
    ss.count_web_orders
FROM 
    CTE_Customer_Sales cs
FULL OUTER JOIN 
    CTE_Item_Sales i ON cs.customer_id = i.item_id
FULL OUTER JOIN 
    CTE_Seasonal_Sales ss ON i.total_quantity_sold > 0
WHERE 
    (cs.total_sales IS NOT NULL OR i.total_quantity_sold IS NOT NULL OR ss.total_sales_catalog IS NOT NULL)
ORDER BY 
    cs.total_sales DESC, 
    i.total_quantity_sold DESC, 
    ss.d_month_seq
LIMIT 100;
