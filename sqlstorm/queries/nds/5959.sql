
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        item i ON r.cs_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    cs.c_customer_id,
    cs.total_spent
FROM 
    TopItems ti
JOIN 
    CustomerSales cs ON cs.total_spent > 500
ORDER BY 
    ti.total_sales DESC, cs.total_spent DESC;
