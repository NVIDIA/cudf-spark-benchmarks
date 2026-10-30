
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
CustomerProfits AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FrequentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        COUNT(DISTINCT sr.sr_item_sk) AS distinct_items_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cp.total_profit,
    ft.return_count,
    ft.distinct_items_returned,
    R.total_quantity,
    R.total_sales
FROM 
    customer c
LEFT JOIN 
    CustomerProfits cp ON c.c_customer_sk = cp.c_customer_sk
LEFT JOIN 
    FrequentReturns ft ON c.c_customer_sk = ft.sr_customer_sk
LEFT JOIN 
    RankedSales R ON R.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM (
            SELECT 
                ws_item_sk,
                RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS item_rank
            FROM 
                web_sales
            GROUP BY 
                ws_item_sk
            HAVING 
                SUM(ws_quantity) > 0
        ) AS RankedItems 
        WHERE item_rank <= 10
    )
WHERE 
    cp.order_count > 5 OR cp.total_profit IS NULL
ORDER BY 
    cp.total_profit DESC, ft.return_count DESC
LIMIT 50;
