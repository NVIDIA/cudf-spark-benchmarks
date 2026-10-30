
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
), 
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_paid) > 1000
), 
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)

SELECT 
    it.i_item_id,
    it.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    hc.total_spent,
    ic.total_stock,
    CASE 
        WHEN ic.total_stock IS NULL THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    item it
LEFT JOIN 
    RankedSales rs ON it.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
JOIN 
    SalesSummary ss ON it.i_item_sk = ss.ws_item_sk
JOIN 
    HighValueCustomers hc ON hc.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
LEFT JOIN 
    InventoryCheck ic ON it.i_item_sk = ic.inv_item_sk
WHERE 
    it.i_current_price > 20
ORDER BY 
    ss.total_sales DESC;
