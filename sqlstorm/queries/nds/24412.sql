WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_value
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 6 AND 8)
        AND i.i_current_price BETWEEN 10 AND 100
),
Summary AS (
    SELECT
        COUNT(*) AS total_sales,
        SUM(ws_sales_price * ws_quantity) AS total_revenue,
        AVG(ws_net_profit) AS average_profit,
        MAX(ws_sales_price) AS max_sales_price
    FROM 
        RankedSales
    WHERE 
        rank_value <= 5
),
Returns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_orders
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_revenue, 0.00) AS total_revenue,
    COALESCE(s.average_profit, 0.00) AS average_profit,
    COALESCE(s.max_sales_price, 0.00) AS max_sales_price
FROM 
    item i
LEFT JOIN 
    Summary s ON i.i_item_sk = s.total_sales
LEFT JOIN 
    Returns r ON i.i_item_sk = r.cr_item_sk
WHERE 
    i.i_rec_start_date >= cast('2002-10-01' as date) - INTERVAL '1 year'
ORDER BY 
    i.i_item_id, 
    total_returns DESC,
    total_sales DESC
LIMIT 100;