
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
), 
returns_data AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    WHERE
        wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_holiday = 'Y')
    GROUP BY 
        wr_returning_customer_sk
), 
combined AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (sd.total_sales - COALESCE(rd.total_returns, 0)) AS net_sales,
        CASE 
            WHEN sd.total_orders > 10 THEN 'Frequent'
            WHEN sd.total_orders BETWEEN 5 AND 10 THEN 'Occasional'
            ELSE 'Rare'
        END AS customer_type
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.ws_bill_customer_sk = rd.customer_sk
), 
ranked_customers AS (
    SELECT 
        c.*,
        cb.*,
        RANK() OVER (PARTITION BY cb.customer_type ORDER BY cb.net_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        combined cb ON c.c_customer_sk = cb.ws_bill_customer_sk
)
SELECT 
    r.customer_type,
    COUNT(*) AS num_customers,
    AVG(r.total_sales) AS avg_total_sales,
    AVG(r.total_returns) AS avg_total_returns,
    SUM(CASE WHEN r.sales_rank <= 10 THEN 1 ELSE 0 END) AS top_customers
FROM 
    ranked_customers r
GROUP BY 
    r.customer_type
HAVING 
    AVG(r.total_sales) > (
        SELECT 
            AVG(total_sales) 
        FROM 
            combined
    ) AND 
    r.customer_type IS NOT NULL
ORDER BY 
    num_customers DESC;
