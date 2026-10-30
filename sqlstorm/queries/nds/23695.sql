
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sale_rank
    FROM 
        web_sales
), 
InventoryCheck AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.c_customer_sk,
    ic.total_quantity_on_hand,
    SUM(RANKED.ws_sales_price * RANKED.ws_quantity * (1 - CASE WHEN RANKED.ws_quantity > 10 THEN 0.1 ELSE 0 END)) AS total_sales,
    cd.cd_gender,
    cd.credit_rating,
    MAX(RANKED.sale_rank) AS max_rank
FROM 
    InventoryCheck ic
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = (
        SELECT DISTINCT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE sale_rank = 1)
        LIMIT 1
    )
JOIN 
    RankedSales RANKED ON RANKED.ws_item_sk = ic.inv_item_sk
LEFT JOIN 
    store_sales ss ON ss.ss_item_sk = RANKED.ws_item_sk
WHERE 
    ic.total_quantity_on_hand IS NOT NULL
GROUP BY 
    cd.c_customer_sk,
    ic.total_quantity_on_hand,
    cd.cd_gender,
    cd.credit_rating
HAVING 
    SUM(RANKED.ws_sales_price * RANKED.ws_quantity) IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10 OFFSET 0;
