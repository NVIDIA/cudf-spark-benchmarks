
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Top_Sales AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales
    FROM 
        Sales_CTE
    WHERE 
        rank <= 5
),
Item_Info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
),
Sales_Details AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_net_profit) AS net_profit,
        s.ss_store_sk
    FROM 
        store_sales s
    INNER JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        s.ss_item_sk, s.ss_store_sk
),
Final_Summary AS (
    SELECT 
        ii.i_item_desc,
        ii.i_current_price,
        COALESCE(ts.total_quantity, 0) AS web_total_quantity,
        COALESCE(ts.total_sales, 0) AS web_total_sales,
        COALESCE(sd.net_profit, 0) AS store_net_profit,
        ii.quantity_on_hand,
        CASE 
            WHEN ii.i_current_price > 100 THEN 'High Value'
            ELSE 'Low Value' 
        END AS price_category
    FROM 
        Item_Info ii
    LEFT JOIN 
        Top_Sales ts ON ii.i_item_sk = ts.ws_item_sk
    LEFT JOIN 
        Sales_Details sd ON ii.i_item_sk = sd.ss_item_sk
)
SELECT 
    price_category,
    COUNT(*) AS item_count,
    SUM(web_total_quantity) AS total_web_quantity,
    SUM(web_total_sales) AS total_web_sales,
    SUM(store_net_profit) AS total_store_net_profit
FROM 
    Final_Summary
GROUP BY 
    price_category
ORDER BY 
    total_web_sales DESC;
