WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1' YEAR)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1' YEAR)
    GROUP BY 
        cs_item_sk
),
customer_ranking AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        i.i_item_desc,
        CASE 
            WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
            WHEN inv.inv_quantity_on_hand BETWEEN 10 AND 50 THEN 'Moderate Stock'
            ELSE 'Sufficient Stock'
        END AS stock_status,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
            WHEN inv.inv_quantity_on_hand BETWEEN 10 AND 50 THEN 'Moderate Stock'
            ELSE 'Sufficient Stock'
        END ORDER BY inv.inv_quantity_on_hand DESC) AS stock_rank
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
)
SELECT 
    cr.full_name,
    cr.purchase_rank,
    ic.stock_status,
    ic.i_item_desc,
    SUM(ss.total_quantity) AS total_quantity_sold,
    SUM(ss.total_sales) AS total_sales_amount
FROM 
    customer_ranking cr
LEFT JOIN 
    sales_summary ss ON cr.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    inventory_check ic ON ss.ws_item_sk = ic.inv_item_sk
WHERE 
    cr.purchase_rank <= 10
GROUP BY 
    cr.full_name, cr.purchase_rank, ic.stock_status, ic.i_item_desc
HAVING 
    SUM(ss.total_quantity) > 0
ORDER BY 
    cr.purchase_rank, total_sales_amount DESC;