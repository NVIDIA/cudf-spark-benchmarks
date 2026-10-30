
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TimeDetails AS (
    SELECT 
        d.d_year, 
        d.d_month_seq,
        d.d_week_seq,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq
), 
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        CustomerDetails cd
    JOIN 
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.c_first_name, cd.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 10000
)
SELECT 
    sct.total_sales,
    sct.total_quantity,
    hv.c_first_name,
    hv.c_last_name,
    hv.total_spent,
    td.d_year,
    td.d_month_seq,
    td.total_orders
FROM 
    SalesCTE sct
JOIN 
    HighValueCustomers hv ON sct.ws_item_sk = hv.c_customer_sk
LEFT JOIN 
    TimeDetails td ON hv.total_spent > 10000
WHERE 
    sct.rn = 1
ORDER BY 
    sct.total_sales DESC, hv.total_spent DESC
LIMIT 50;
