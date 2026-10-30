
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerProducts AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        i.i_item_id,
        i.i_item_desc,
        ws.ws_sales_price,
        ws.ws_quantity
    FROM 
        RankedCustomers rc
    JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    cp.c_first_name,
    cp.c_last_name,
    COUNT(cp.i_item_id) AS products_bought,
    SUM(cp.ws_sales_price) AS total_spent,
    MAX(cp.ws_sales_price) AS max_spent_on_single_item
FROM 
    CustomerProducts cp
GROUP BY 
    cp.c_first_name, cp.c_last_name
ORDER BY 
    total_spent DESC
LIMIT 20;
