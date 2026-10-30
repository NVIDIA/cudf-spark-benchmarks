WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459757 AND 2459810 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
BestSellingItems AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459757 AND 2459810 
    GROUP BY 
        i.i_item_sk, i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    bsi.total_quantity_sold,
    CASE 
        WHEN cs.total_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM 
    CustomerSales cs
LEFT JOIN 
    StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
LEFT JOIN 
    BestSellingItems bsi ON bsi.total_quantity_sold IN (SELECT total_quantity_sold FROM BestSellingItems)
WHERE 
    cs.sales_rank = 1
ORDER BY 
    cs.total_web_sales DESC;