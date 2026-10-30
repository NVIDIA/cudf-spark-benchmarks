
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year AS sales_year,
        c.c_birth_year AS customer_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.c_birth_year, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.sales_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.sales_year,
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_sales,
    rs.order_count,
    rs.customer_birth_year,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.hd_income_band_sk
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_year, rs.total_sales DESC;
