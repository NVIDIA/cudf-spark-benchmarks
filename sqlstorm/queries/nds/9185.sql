
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        d.d_year, 
        d.d_month_seq
), ItemAnalysis AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        (sd.total_sales - sd.total_discount) AS net_sales,
        (sd.total_sales / NULLIF(sd.total_quantity, 0)) AS avg_sales_price
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.total_quantity > 100
), CustomerInsights AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ia.net_sales) AS total_spent,
        COUNT(DISTINCT ia.i_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        ItemAnalysis ia ON ws.ws_item_sk = ia.i_item_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_spent,
    ci.unique_items_purchased,
    RANK() OVER (ORDER BY ci.total_spent DESC) AS rank_by_spent
FROM 
    CustomerInsights ci
WHERE 
    ci.total_spent > 1000
ORDER BY 
    rank_by_spent;
