
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        w.w_warehouse_name,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk, 
        w.w_warehouse_name, 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    w_warehouse_name,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(total_quantity) AS total_quantity,
    SUM(total_sales) AS total_sales,
    SUM(total_discount) AS total_discount,
    AVG(total_sales) AS avg_sales_per_customer,
    COUNT(*) AS total_transactions,
    AVG(sales_rank) AS avg_sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    w_warehouse_name
ORDER BY 
    total_sales DESC;
