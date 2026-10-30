
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_sales,
        ri.total_orders,
        item.i_item_desc AS item_desc,
        ROW_NUMBER() OVER (ORDER BY ri.total_sales DESC) AS item_rank
    FROM 
        RankedSales ri
    JOIN 
        item ON ri.ws_item_sk = item.i_item_sk
    WHERE 
        ri.rn = 1
),
SalesBreakdown AS (
    SELECT 
        ti.ws_item_sk,
        ti.item_desc,
        COUNT(DISTINCT ws_order_number) AS unique_order_count,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
    GROUP BY 
        ti.ws_item_sk, ti.item_desc
),
ItemDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        cd_gender
)
SELECT 
    ti.item_desc,
    sb.unique_order_count,
    sb.total_discount,
    sb.total_net_profit,
    id.customer_count,
    CASE 
        WHEN sb.unique_order_count > 100 THEN 'High Demand'
        WHEN sb.unique_order_count BETWEEN 50 AND 100 THEN 'Moderate Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    SalesBreakdown sb
JOIN 
    TopItems ti ON sb.ws_item_sk = ti.ws_item_sk
LEFT JOIN 
    ItemDemographics id ON id.customer_count IS NOT NULL
WHERE 
    sb.total_net_profit IS NOT NULL
ORDER BY 
    sb.total_net_profit DESC, ti.item_desc ASC
LIMIT 10;
