
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cp.c_customer_id,
    cp.purchase_count,
    cp.total_spent,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales
FROM 
    CustomerPurchases cp
JOIN 
    TopItems ti ON cp.purchase_count > 0
ORDER BY 
    cp.total_spent DESC, ti.total_sales DESC
LIMIT 100;
