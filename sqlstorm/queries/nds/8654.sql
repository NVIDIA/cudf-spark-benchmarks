
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_education_status IN ('Bachelors', 'Masters')
        AND i.i_current_price BETWEEN 10.00 AND 100.00
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        ri.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item ri ON rs.cs_item_sk = ri.i_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ROUND(ti.total_sales / ti.total_quantity, 2) AS average_sales_price
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales DESC;
