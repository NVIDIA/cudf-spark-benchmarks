
WITH  sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
top_sales AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_quantity, 
        ss.total_sales
    FROM 
        sales_summary ss
    WHERE 
        ss.rn = 1
), 
customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year
), 
return_analysis AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    cm.order_count,
    cm.total_spent,
    ra.total_returns,
    ra.return_count,
    (ts.total_sales - COALESCE(ra.total_returns, 0)) AS net_sales
FROM 
    item it
LEFT JOIN 
    top_sales ts ON it.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    customer_metrics cm ON cm.order_count > 0
LEFT JOIN 
    return_analysis ra ON it.i_item_sk = ra.cr_item_sk
WHERE 
    (cm.total_spent > 1000 OR ra.return_count IS NULL)
    AND (ts.total_quantity IS NOT NULL OR ts.total_quantity > 0)
ORDER BY 
    net_sales DESC
LIMIT 50;
