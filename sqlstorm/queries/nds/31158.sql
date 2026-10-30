
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) as sales_rank,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, 
        ws_sold_date_sk
), 
customer_performance AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(wb.ws_net_profit) * 1.1, 0) AS adjusted_net_profit,
        COUNT(DISTINCT wb.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales wb ON c.c_customer_sk = wb.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    SUM(ss.total_quantity) AS grand_total_quantity,
    SUM(ss.total_sales) AS grand_total_sales,
    cp.c_customer_sk,
    cp.adjusted_net_profit,
    cp.order_count,
    d.d_date AS sales_date
FROM 
    sales_summary ss
JOIN 
    customer_performance cp ON ss.ws_item_sk = cp.c_customer_sk
JOIN 
    date_dim d 
    ON d.d_date_sk = ss.ws_sold_date_sk
WHERE 
    d.d_year = 2023 AND
    (cp.order_count > 10 OR cp.adjusted_net_profit IS NOT NULL)
GROUP BY 
    cp.c_customer_sk, cp.adjusted_net_profit, cp.order_count, d.d_date
ORDER BY 
    grand_total_sales DESC;
