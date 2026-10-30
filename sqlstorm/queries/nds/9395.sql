
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2001 AND d.d_moy IN (6, 7)  
    )
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
frequent_items AS (
    SELECT 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_sold
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
    HAVING SUM(ws.ws_quantity) > 1000  
),
customer_summary AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        COALESCE(fi.total_sold, 0) AS total_item_sales,
        ra.total_sales,
        rc.sales_rank
    FROM ranked_customers rc
    LEFT JOIN frequent_items fi ON rc.c_customer_id = fi.i_item_id  
    LEFT JOIN (
        SELECT 
            c.c_customer_id,
            SUM(ws.ws_sales_price) AS total_sales
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        GROUP BY c.c_customer_id
    ) ra ON rc.c_customer_id = ra.c_customer_id
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_item_sales,
    cs.total_sales,
    cs.sales_rank
FROM customer_summary cs
WHERE cs.total_sales > 5000  
ORDER BY cs.sales_rank, cs.total_sales DESC
LIMIT 100;
