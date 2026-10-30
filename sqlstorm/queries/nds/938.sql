WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_quantity,
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount
FROM 
    customer c
LEFT JOIN 
    TopItems ti ON c.c_customer_sk = ti.cs_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    c.c_birth_year > (2001 - 30)  
    AND c.c_preferred_cust_flag = 'Y'
ORDER BY 
    ti.total_sales DESC, c.c_last_name ASC;