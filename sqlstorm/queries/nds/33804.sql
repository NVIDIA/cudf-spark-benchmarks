
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 20230101
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
),
AggregateSales AS (
    SELECT 
        d.d_year,
        i.i_item_id,
        SUM(sd.total_revenue) AS total_revenue,
        AVG(NULLIF(sd.total_sold, 0)) AS avg_quantity_sold
    FROM 
        SalesData sd
    INNER JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    INNER JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        d.d_year, i.i_item_id
),
RevenueBand AS (
    SELECT 
        CASE 
            WHEN total_revenue < 1000 THEN 'Low'
            WHEN total_revenue BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS revenue_band,
        COUNT(*) AS item_count
    FROM 
        AggregateSales
    GROUP BY 
        revenue_band
),
TopStores AS (
    SELECT 
        s.s_store_name,
        SUM(ss_ext_sales_price) AS store_revenue
    FROM 
        store_sales
    JOIN 
        store s ON store_sales.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
    ORDER BY 
        store_revenue DESC
    LIMIT 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_net_paid) AS customer_spent
    FROM 
        web_sales 
    JOIN 
        customer c ON web_sales.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws_sold_date_sk >= 20230101
    GROUP BY 
        c.c_customer_id
)

SELECT 
    COALESCE(ts.s_store_name, 'N/A') AS Store_Name,
    COALESCE(rb.revenue_band, 'N/A') AS Revenue_Band,
    cs.c_customer_id AS Customer_ID,
    cs.customer_spent AS Total_Spent,
    ROW_NUMBER() OVER(PARTITION BY COALESCE(rb.revenue_band, 'N/A') ORDER BY cs.customer_spent DESC) AS Rank
FROM 
    RevenueBand rb
FULL OUTER JOIN 
    TopStores ts ON TRUE
LEFT JOIN 
    CustomerSales cs ON ts.s_store_name = cs.c_customer_id
ORDER BY 
    rb.revenue_band, cs.customer_spent DESC;
