
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_net_paid, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
),
AggregatedSales AS (
    SELECT 
        sd.cd_gender,
        sd.cd_marital_status,
        COUNT(sd.ws_item_sk) AS total_sales,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        SUM(sd.inv_quantity_on_hand) AS total_inventory
    FROM 
        SalesData sd
    GROUP BY 
        sd.cd_gender, 
        sd.cd_marital_status
)
SELECT 
    ag.cd_gender,
    ag.cd_marital_status,
    ag.total_sales,
    ag.total_quantity,
    ag.total_net_paid,
    ag.avg_sales_price,
    ag.total_inventory,
    (ag.total_net_paid / NULLIF(ag.total_sales, 0)) AS avg_net_paid_per_sale
FROM 
    AggregatedSales ag
WHERE 
    ag.total_quantity > 100
ORDER BY 
    ag.total_net_paid DESC
LIMIT 50;
