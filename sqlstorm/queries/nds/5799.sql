
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2022
),
MaxSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.ws_order_number
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS rank
    FROM 
        customer c 
    JOIN 
        MaxSales r ON c.c_customer_sk = r.ws_order_number
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.total_sales
FROM 
    CustomerDetails cd
WHERE 
    cd.rank <= 10
ORDER BY 
    cd.total_sales DESC;
