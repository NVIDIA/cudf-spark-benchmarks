
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
PopularItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name
    HAVING 
        SUM(ws.ws_quantity) > 100
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        pc.total_sales_quantity,
        pc.total_sales_revenue,
        RANK() OVER (ORDER BY pc.total_sales_revenue DESC) AS revenue_rank
    FROM 
        RankedCustomers rc
    JOIN 
        store_sales ss ON rc.c_customer_sk = ss.ss_customer_sk
    JOIN 
        PopularItems pc ON ss.ss_item_sk = pc.i_item_sk
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales_quantity,
    tc.total_sales_revenue
FROM 
    TopCustomers tc
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.total_sales_revenue DESC;
