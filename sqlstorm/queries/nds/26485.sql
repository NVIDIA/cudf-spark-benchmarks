
WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(i.i_item_desc, 1, 1) ORDER BY i.i_current_price DESC) AS rank
    FROM 
        item i
    WHERE 
        i.i_item_desc IS NOT NULL
),
TopItems AS (
    SELECT 
        rt.i_item_id,
        rt.i_item_desc,
        rt.i_current_price
    FROM 
        RankedItems rt
    WHERE 
        rt.rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.i_item_id,
    ti.i_item_desc,
    ti.i_current_price
FROM 
    CustomerInfo ci
JOIN 
    TopItems ti ON ci.c_customer_id LIKE '%' || ti.i_item_id || '%'
ORDER BY 
    ci.c_customer_id, ti.i_current_price DESC;
