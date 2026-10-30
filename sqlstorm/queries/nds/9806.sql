
WITH SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS order_count,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, d.d_year, d.d_month_seq, sm.sm_type
),
SalesRanked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    s.total_sales,
    s.total_discount,
    s.order_count,
    s.sm_type,
    s.unique_items_sold,
    s.sales_rank
FROM 
    SalesRanked s
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.d_year, s.d_month_seq, s.total_sales DESC;
