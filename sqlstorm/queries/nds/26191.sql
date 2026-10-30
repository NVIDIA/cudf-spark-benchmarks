
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_email_address, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales_quantity, 
        SUM(ws.ws_net_paid) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        RankedCustomers rc ON rc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        sd.total_sales_quantity, 
        sd.total_sales_amount,
        RANK() OVER (ORDER BY sd.total_sales_amount DESC) AS item_rank
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    tsi.i_item_id, 
    tsi.i_item_desc, 
    tsi.total_sales_quantity,
    tsi.total_sales_amount
FROM 
    TopSellingItems tsi
WHERE 
    tsi.item_rank <= 5
ORDER BY 
    tsi.total_sales_amount DESC;
