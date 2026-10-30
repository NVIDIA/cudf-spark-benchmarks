
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SaleRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 0
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(ranked.ws_quantity) AS total_sold
    FROM 
        RankedSales ranked
    JOIN 
        item ON ranked.ws_item_sk = item.i_item_sk
    WHERE 
        ranked.SaleRank = 1
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesByDemographics AS (
    SELECT 
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(t.total_sold) AS total_items_sold
    FROM 
        TopSellingItems t
    JOIN 
        CustomerInfo ci ON ci.total_orders > 5
    GROUP BY 
        ci.cd_gender, ci.cd_marital_status
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    COALESCE(sd.total_items_sold, 0) AS total_items_sold,
    CASE 
        WHEN sd.cd_gender = 'M' THEN 'Male'
        WHEN sd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS Gender_Description
FROM 
    SalesByDemographics sd
FULL OUTER JOIN 
    customer_demographics cd ON sd.cd_gender = cd.cd_gender
WHERE 
    sd.total_items_sold > 100 OR sd.total_items_sold IS NULL
ORDER BY 
    total_items_sold DESC;
