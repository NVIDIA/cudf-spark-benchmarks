WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.average_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS item_rank
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        i.i_current_price > 0
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_sales,
    tsi.average_profit
FROM 
    RankedCustomers rc
JOIN 
    TopSellingItems tsi ON tsi.item_rank <= 10 
WHERE 
    rc.purchase_rank <= 5 
ORDER BY 
    rc.cd_gender,
    tsi.total_sales DESC;