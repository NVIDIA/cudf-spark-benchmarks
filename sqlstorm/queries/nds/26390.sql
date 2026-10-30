
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 10
),
ShippingData AS (
    SELECT 
        wsm.ws_ship_date_sk,
        wsm.ws_item_sk,
        SUM(wsm.ws_quantity) AS total_quantity,
        MAX(wsm.ws_sales_price) AS max_price,
        MIN(wsm.ws_sales_price) AS min_price
    FROM 
        web_sales wsm
    JOIN 
        TopCustomers tc ON wsm.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        wsm.ws_ship_date_sk, wsm.ws_item_sk
)
SELECT 
    d.d_date AS sales_date,
    id.i_item_id,
    id.i_item_desc,
    sd.total_quantity,
    sd.max_price,
    sd.min_price
FROM 
    ShippingData sd
JOIN 
    date_dim d ON sd.ws_ship_date_sk = d.d_date_sk
JOIN 
    item id ON sd.ws_item_sk = id.i_item_sk
ORDER BY 
    d.d_date, total_quantity DESC;
