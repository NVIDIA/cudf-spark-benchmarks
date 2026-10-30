
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(s.ss_net_profit) AS total_profit
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)

SELECT 
    cdem.c_customer_sk,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cdem.cd_education_status,
    sales.total_quantity,
    sales.total_sales,
    inv.total_on_hand,
    COALESCE(sales.total_sales, 0) AS net_sales,
    CASE 
        WHEN cdem.total_purchases > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM 
    CustomerDemographics cdem
LEFT JOIN 
    SalesCTE sales ON cdem.c_customer_sk = sales.ws_item_sk 
LEFT JOIN 
    InventoryStatus inv ON sales.ws_item_sk = inv.inv_item_sk
WHERE 
    cdem.cd_gender IS NOT NULL 
    AND (cdem.cd_marital_status IS NULL OR cdem.cd_marital_status != 'D')
ORDER BY 
    cdem.total_profit DESC, sales.total_sales ASC
LIMIT 100;
