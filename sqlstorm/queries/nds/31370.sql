
WITH  sales_hierarchy AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        sr_return_quantity,
        COALESCE(sr_return_amt, 0) AS total_return_amt,
        'Store' AS sales_type
    FROM 
        store_sales ss
    LEFT JOIN 
        store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number

    UNION ALL

    SELECT 
        cs.cs_item_sk,
        cs.cs_ship_customer_sk,
        cs.cs_sold_date_sk,
        cr_return_quantity,
        COALESCE(cr_return_amount, 0) AS total_return_amt,
        'Catalog' AS sales_type
    FROM 
        catalog_sales cs
    LEFT JOIN 
        catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk AND cs.cs_order_number = cr.cr_order_number

    UNION ALL

    SELECT 
        ws.ws_item_sk,
        ws.ws_ship_customer_sk,
        ws.ws_sold_date_sk,
        wr_return_quantity,
        COALESCE(wr_return_amt, 0) AS total_return_amt,
        'Web' AS sales_type
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
), sales_summary AS (
    SELECT 
        sh.ss_item_sk,
        sh.sales_type,
        COUNT(DISTINCT sh.ss_customer_sk) AS unique_customers,
        SUM(sh.total_return_amt) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sh.ss_item_sk ORDER BY SUM(sh.total_return_amt) DESC) AS rank
    FROM 
        sales_hierarchy sh
    GROUP BY 
        sh.ss_item_sk, sh.sales_type
), ranked_sales AS (
    SELECT 
        s.ss_item_sk,
        s.sales_type,
        s.unique_customers,
        s.total_return_amt
    FROM 
        sales_summary s
    WHERE 
        s.rank <= 5
)
SELECT 
    r.ss_item_sk,
    r.sales_type,
    r.unique_customers,
    r.total_return_amt,
    COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
    CASE 
        WHEN r.total_return_amt > 1000 THEN 'High Return'
        WHEN r.total_return_amt BETWEEN 500 AND 1000 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    ranked_sales r
LEFT JOIN 
    item i ON r.ss_item_sk = i.i_item_sk
ORDER BY 
    r.total_return_amt DESC, r.sales_type;
