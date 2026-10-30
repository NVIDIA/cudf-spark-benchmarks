
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_sales_price,
        rs.ws_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 10
),
StoreSalesDetails AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
CombinedSales AS (
    SELECT 
        ts.ws_item_sk,
        SUM(ts.ws_quantity) AS web_quantity,
        COALESCE(SUM(ws.total_quantity), 0) AS store_quantity,
        SUM(ts.ws_net_paid) AS total_web_sales,
        COALESCE(SUM(ws.total_net_paid), 0) AS total_store_sales,
        CASE 
            WHEN COALESCE(SUM(ws.total_net_paid), 0) = 0 THEN NULL 
            ELSE SUM(ts.ws_net_paid) / NULLIF(SUM(ws.total_net_paid), 0) 
        END AS sales_ratio
    FROM 
        TopSales ts
    LEFT JOIN 
        StoreSalesDetails ws ON ts.ws_item_sk = ws.ss_item_sk
    GROUP BY 
        ts.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cs.web_quantity,
    cs.store_quantity,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.sales_ratio
FROM 
    CombinedSales cs
JOIN 
    customer c ON cs.ws_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (ca.ca_state = 'NY' OR ca.ca_state IS NULL)
    AND cs.sales_ratio IS NOT NULL
    AND cs.sales_ratio > 1.0
ORDER BY 
    cs.total_web_sales DESC,
    c.c_last_name ASC
LIMIT 50;
