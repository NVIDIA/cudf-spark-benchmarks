
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM
        web_sales ws
),
FilteredSales AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_revenue
    FROM
        RankedSales rs
    WHERE
        rs.sale_rank <= 5
    GROUP BY
        rs.ws_item_sk
),
HighValueItems AS (
    SELECT
        fs.ws_item_sk,
        fs.total_revenue,
        i.i_item_desc,
        CASE 
            WHEN fs.total_revenue IS NULL THEN 'No Revenue'
            WHEN fs.total_revenue > 10000 THEN 'High Roller'
            WHEN fs.total_revenue BETWEEN 5000 AND 10000 THEN 'Mid Tier'
            ELSE 'Budget Item'
        END AS revenue_category
    FROM
        FilteredSales fs
    LEFT JOIN
        item i ON fs.ws_item_sk = i.i_item_sk
),
CustomerPurchaseDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS lifetime_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TotalRevenue AS (
    SELECT
        SUM(ws.ws_sales_price * ws.ws_quantity) AS grand_total_revenue
    FROM
        web_sales ws
)
SELECT
    hi.ws_item_sk,
    hi.total_revenue,
    hi.revenue_category,
    cp.c_customer_id,
    cp.lifetime_value,
    cp.order_count,
    (CASE
        WHEN hi.total_revenue > (SELECT 
                                    AVG(total_revenue) 
                                   FROM 
                                    FilteredSales) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END) AS comparison_to_average,
    (SELECT grand_total_revenue FROM TotalRevenue) AS overall_revenue
FROM
    HighValueItems hi
JOIN
    CustomerPurchaseDetails cp ON hi.ws_item_sk = (SELECT rs.ws_item_sk FROM RankedSales rs ORDER BY rs.ws_sales_price DESC LIMIT 1)
WHERE
    hi.revenue_category != 'No Revenue'
ORDER BY
    hi.total_revenue DESC
LIMIT 10;
