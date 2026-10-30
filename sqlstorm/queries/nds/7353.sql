
WITH SalesDetails AS (
    SELECT 
        ws.ws_sold_date_sk AS sold_date,
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        cd.cd_gender AS customer_gender,
        cd.cd_marital_status AS marital_status,
        dd.d_year AS sales_year,
        w.w_warehouse_name AS warehouse_name,
        s.s_store_name AS store_name,
        dd.d_month_seq AS month_seq,
        dd.d_quarter_seq AS quarter_seq
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store AS s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        sold_date, item_id, customer_gender, marital_status, sales_year, warehouse_name, store_name, month_seq, quarter_seq
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sold_date ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesDetails
)
SELECT 
    sold_date, 
    item_id,
    total_quantity_sold,
    total_sales,
    customer_gender,
    marital_status,
    sales_year,
    warehouse_name,
    store_name,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    sold_date, total_sales DESC;
