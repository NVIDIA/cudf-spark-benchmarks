
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ranked.total_quantity,
        ranked.total_sales
    FROM 
        RankedSales ranked
    JOIN 
        item ON ranked.ws_item_sk = item.i_item_sk
    WHERE 
        ranked.rank = 1
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
ShippingDetails AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws_ext_ship_cost) AS total_ship_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)

SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    cd.cd_gender,
    cd.customer_count,
    cd.total_purchase_estimate,
    sd.total_ship_cost,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No Customers'
        ELSE 'Customers Exist'
    END AS customer_status
FROM 
    TopSales ts
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_gender = 'M'
LEFT JOIN 
    ShippingDetails sd ON sd.total_ship_cost > 1000
ORDER BY 
    ts.total_sales DESC
LIMIT 10;
