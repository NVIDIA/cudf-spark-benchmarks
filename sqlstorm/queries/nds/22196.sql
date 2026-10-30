
WITH TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND c.c_birth_month IN (4, 5, 6) 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_quantity) > 10
),
SalesAgg AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS annual_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
ItemDetails AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(COALESCE(cc.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity,
        SUM(COALESCE(cc.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cc ON i.i_item_sk = cc.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
)
SELECT 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name,
    COALESCE(ia.i_item_id, 'N/A') AS item_id, 
    COALESCE(ia.i_item_desc, 'N/A') AS item_desc,
    COALESCE(ia.total_quantity, 0) AS total_item_quantity,
    COALESCE(ia.total_net_profit, 0) AS total_item_net_profit,
    sa.d_year,
    sa.annual_sales,
    CASE 
        WHEN tc.total_spent >= 500 THEN 'VIP'
        WHEN tc.total_spent BETWEEN 250 AND 499 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    ItemDetails ia ON tc.c_customer_id = ia.i_item_id
JOIN 
    SalesAgg sa ON YEAR(CURRENT_DATE) - sa.d_year <= 5
ORDER BY 
    tc.total_spent DESC, 
    sa.annual_sales DESC;
