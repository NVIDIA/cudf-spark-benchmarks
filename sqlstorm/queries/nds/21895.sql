WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, w.w_warehouse_name
), 
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerInfo
    WHERE 
        total_sales IS NOT NULL
), 
LastYearSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS last_year_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 1
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.w_warehouse_name,
    rc.cd_gender,
    rc.cd_marital_status,
    COALESCE(l.last_year_sales, 0) AS last_year_sales,
    rc.total_sales,
    CASE 
        WHEN rc.sales_rank = 1 THEN 'Top Performer'
        WHEN rc.total_sales > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    RankedCustomers rc
LEFT JOIN 
    LastYearSales l ON rc.c_customer_sk = l.c_customer_sk
WHERE 
    rc.sales_rank <= 5
    AND (rc.cd_gender = 'F' OR rc.cd_marital_status = 'M')
ORDER BY 
    rc.cd_gender, rc.total_sales DESC;