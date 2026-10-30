
WITH Combined_Sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_item_sk AS item_id,
        COALESCE(NULLIF(ws.ws_bill_cdemo_sk, 0), NULL) AS bill_demo_sk,
        COALESCE(NULLIF(ws.ws_ship_cdemo_sk, 0), NULL) AS ship_demo_sk,
        ws.ws_sales_price AS sales_price,
        (ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_sales,
        dd.d_month_seq AS month_sequence,
        dd.d_year AS sale_year
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
),
Sales_Stats AS (
    SELECT 
        order_number,
        item_id,
        bill_demo_sk,
        ship_demo_sk,
        SUM(net_sales) AS total_net_sales,
        COUNT(order_number) AS order_count,
        AVG(sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY bill_demo_sk ORDER BY SUM(net_sales) DESC) AS sales_rank
    FROM 
        Combined_Sales
    GROUP BY 
        order_number, item_id, bill_demo_sk, ship_demo_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(ss.order_number) AS total_orders,
    SUM(ss.total_net_sales) AS lifetime_value,
    MAX(ss.avg_sales_price) AS highest_avg_price,
    MIN(ss.total_net_sales) AS lowest_value,
    ss.sales_rank
FROM 
    Sales_Stats ss
JOIN
    customer c ON ss.bill_demo_sk = c.c_current_cdemo_sk
JOIN
    customer_demographics cd ON ss.bill_demo_sk = cd.cd_demo_sk
WHERE 
    ss.sales_rank <= 5
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ss.sales_rank
ORDER BY 
    lifetime_value DESC;
