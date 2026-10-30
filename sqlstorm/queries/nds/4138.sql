
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ProductSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id, 
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        AVG(cs.cs_sales_price) AS avg_catalog_price
    FROM 
        item i
    JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_web_sales,
        cs.total_orders,
        ps.total_catalog_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS web_sales_rank,
        ROW_NUMBER() OVER (ORDER BY ps.total_catalog_sales DESC) AS catalog_sales_rank
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ProductSales ps ON cs.c_customer_sk = ps.i_item_sk
),
StoreReturnsSummary AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_store_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(rs.avg_return_quantity, 0) AS avg_return_quantity,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_web_sales,
    sr.total_orders,
    sr.web_sales_rank,
    sr.catalog_sales_rank
FROM 
    store s
LEFT JOIN 
    StoreReturnsSummary rs ON s.s_store_sk = rs.sr_store_sk
JOIN 
    SalesRanked sr ON s.s_store_sk = sr.c_customer_sk
WHERE 
    (sr.total_orders > 5 OR sr.total_web_sales > 1000)
    AND sr.web_sales_rank <= 10
ORDER BY 
    total_web_sales DESC, 
    total_orders DESC;
