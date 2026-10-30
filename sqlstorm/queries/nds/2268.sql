WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id, 
        rs.total_sales, 
        rs.order_count,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rs.sales_rank <= 50
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(ws_ext_sales_price) AS total_sales_by_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
),
SalesTrends AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    sbs.total_sales_by_state,
    COALESCE(st.yearly_sales, 0) AS yearly_sales,
    st.sales_rank AS year_sales_rank
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    SalesByState sbs ON hvc.gender = 'M'  
LEFT JOIN 
    SalesTrends st ON hvc.total_sales > 1000 AND st.d_year = 2001
WHERE 
    hvc.total_sales > 5000
ORDER BY 
    hvc.total_sales DESC, hvc.c_last_name;