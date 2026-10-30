
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerRank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year ASC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        CustomerRank cr
    LEFT JOIN 
        web_sales ws ON cr.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cr.gender_rank <= 10
    GROUP BY 
        cr.c_customer_sk, cr.c_first_name, cr.c_last_name
),
ItemPopularity AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COUNT(DISTINCT s.ss_ticket_number) AS store_sales_count,
        COALESCE(SUM(ws.ws_quantity), 0) AS online_sales_count
    FROM 
        item i
    LEFT JOIN 
        store_sales s ON i.i_item_sk = s.ss_item_sk 
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    ip.i_item_id,
    ip.i_item_desc,
    ip.store_sales_count,
    ip.online_sales_count,
    r.total_quantity,
    r.total_sales
FROM 
    TopCustomers t
JOIN 
    ItemPopularity ip ON t.total_spent > 1000
JOIN 
    RankedSales r ON ip.i_item_sk = r.ws_item_sk
ORDER BY 
    t.total_spent DESC, ip.store_sales_count + ip.online_sales_count DESC;
