
WITH  CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM 
        web_returns
    GROUP BY
        wr_returning_customer_sk
    HAVING 
        SUM(wr_return_quantity) > 0
),
WarehouseInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM
        inventory
    GROUP BY 
        inv_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ci.total_returned_quantity,
    ci.total_returned_amt,
    wi.total_quantity_on_hand,
    wi.total_quantity_on_hand - COALESCE(ci.total_returned_quantity, 0) AS remaining_inventory
FROM 
    CustomerDemographics AS cd
LEFT JOIN 
    CustomerReturns AS ci ON cd.c_customer_sk = ci.wr_returning_customer_sk
JOIN 
    WarehouseInventory AS wi ON wi.inv_item_sk = cd.c_customer_sk
WHERE 
    cd.rank <= 5
ORDER BY 
    cd.cd_purchase_estimate DESC
LIMIT 100;

