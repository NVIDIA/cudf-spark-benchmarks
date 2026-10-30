
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales_price,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_net_paid) AS total_paid,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12 LIMIT 1) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2024 AND d_moy = 1 LIMIT 1)
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_sales_price,
        sd.total_discount,
        sd.total_paid,
        DENSE_RANK() OVER (ORDER BY sd.total_paid DESC) AS sales_rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_quantity > 100
),
ReturnsData AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
)
SELECT 
    ti.cs_item_sk,
    ti.total_quantity AS items_sold,
    ti.total_sales_price,
    ti.total_discount,
    ti.total_paid,
    COALESCE(r.total_returned, 0) AS total_returns,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN COALESCE(r.total_returned, 0) > 0 THEN 
            (ti.total_paid - COALESCE(r.total_returned_amount, 0)) 
        ELSE 
            ti.total_paid 
    END AS net_sales
FROM 
    TopItems ti
LEFT JOIN 
    ReturnsData r ON ti.cs_item_sk = r.cr_item_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.sales_rank;
