
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_units_sold,
        AVG(ws.ws_net_paid) AS average_ticket_value
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
        AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.ws_sold_date_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_purchases
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), ranked_customers AS (
    SELECT 
        cus.cd_gender,
        cus.total_purchases,
        DENSE_RANK() OVER (PARTITION BY cus.cd_gender ORDER BY cus.total_purchases DESC) AS purchase_rank
    FROM 
        customer_summary AS cus
    WHERE 
        cus.total_purchases IS NOT NULL
)

SELECT 
    ss.ws_sold_date_sk,
    ss.total_sales,
    ss.total_orders,
    ss.total_units_sold,
    ss.average_ticket_value,
    rc.cd_gender,
    rc.total_purchases,
    rc.purchase_rank
FROM 
    sales_summary AS ss
LEFT JOIN 
    ranked_customers AS rc ON rc.purchase_rank <= 10
ORDER BY 
    ss.total_sales DESC,
    rc.cd_gender ASC;
