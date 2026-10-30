
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_profit
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank <= 10
),
CustomerInfo AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer
    JOIN 
        customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    cust.cd_gender,
    cust.cd_marital_status,
    CASE 
        WHEN cust.cd_purchase_estimate IS NULL THEN 'Unknown'
        ELSE CAST(cust.cd_purchase_estimate AS VARCHAR(20))
    END AS purchase_estimate,
    item.i_item_id,
    item.i_item_desc,
    item.total_quantity,
    item.total_profit
FROM 
    CustomerInfo cust
LEFT JOIN 
    TopItems item ON cust.gender_rank = item.total_quantity
WHERE 
    cust.cd_marital_status = 'M' OR cust.cd_gender = 'F'
    AND item.total_profit > 0
    AND (item.total_quantity IS NOT NULL AND item.total_quantity > 5)
UNION 
SELECT 
    NULL AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    'N/A' AS purchase_estimate,
    item.i_item_id,
    item.i_item_desc,
    item.total_quantity,
    item.total_profit
FROM 
    TopItems item
WHERE 
    item.total_profit < 0
ORDER BY 
    purchase_estimate DESC NULLS LAST,
    total_profit DESC;
