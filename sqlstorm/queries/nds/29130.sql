
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_desc,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
    GROUP BY 
        ws.ws_item_sk, i.i_item_desc
    ORDER BY 
        order_count DESC
    LIMIT 10
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.c_email_address,
    rc.cd_gender,
    pi.i_item_desc,
    pi.order_count
FROM 
    ranked_customers rc
JOIN 
    popular_items pi ON rc.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = pi.ws_item_sk)
WHERE 
    rc.purchase_rank <= 5
ORDER BY 
    rc.cd_gender, pi.order_count DESC;
