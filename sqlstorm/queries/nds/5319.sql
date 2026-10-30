WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND 
        dd.d_moy IN (6, 7)   
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        SalesData sd
)
SELECT 
    ti.cs_item_sk,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_sales_price,
    r.r_reason_desc
FROM 
    TopItems ti
JOIN 
    item i ON ti.cs_item_sk = i.i_item_sk
LEFT JOIN 
    catalog_returns cr ON ti.cs_item_sk = cr.cr_item_sk
LEFT JOIN 
    reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_sales DESC;