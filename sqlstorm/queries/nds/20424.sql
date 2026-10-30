
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sale_rank,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS total_net_profit,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS sale_count
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_net_profit,
        cs.cs_sales_price,
        cs.cs_list_price,
        (rs.total_net_profit / NULLIF(cs.cs_sales_price, 0)) AS profit_ratio
    FROM 
        RankedSales rs
    JOIN 
        catalog_sales cs ON rs.ws_item_sk = cs.cs_item_sk
    WHERE 
        rs.sale_rank = 1 AND
        (rs.total_net_profit > 5000 OR (rs.total_net_profit / NULLIF(cs.cs_sales_price, 0)) > 0.5)
),
FilteredItems AS (
    SELECT 
        hi.ws_item_sk,
        hi.total_net_profit,
        CASE 
            WHEN hi.total_net_profit > 10000 THEN 'High Profit'
            WHEN hi.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        HighProfitItems hi
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        EXISTS (
            SELECT 1 FROM FilteredItems fi WHERE fi.ws_item_sk = ws.ws_item_sk
        )
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT 
    cp.c_customer_id,
    cp.c_first_name,
    cp.c_last_name,
    cp.purchase_count,
    cp.total_spent,
    fi.profit_category
FROM 
    CustomerPurchases cp
JOIN 
    FilteredItems fi ON cp.purchase_count > 5
ORDER BY 
    cp.total_spent DESC
LIMIT 10;
