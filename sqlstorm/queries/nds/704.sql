
WITH TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
CustomerRanking AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_profit DESC) AS rank
    FROM 
        TopCustomers
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
FilteredItems AS (
    SELECT 
        *,
        CASE 
            WHEN total_quantity_sold > 100 THEN 'High'
            WHEN total_quantity_sold BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        ItemSales
)
SELECT 
    CR.c_first_name,
    CR.c_last_name,
    CR.cd_gender,
    F.i_item_id,
    F.total_quantity_sold,
    F.sales_category
FROM 
    CustomerRanking CR
INNER JOIN 
    FilteredItems F ON CR.rank <= 5
LEFT JOIN 
    store s ON CR.c_customer_sk = s.s_store_sk
WHERE 
    s.s_state IS NULL OR s.s_state = 'CA'
ORDER BY 
    CR.cd_gender, F.total_quantity_sold DESC;
