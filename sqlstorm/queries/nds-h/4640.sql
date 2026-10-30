
WITH  OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighlyProfitable AS (
    SELECT 
        o.o_orderkey AS orderkey,
        os.total_revenue,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        os.total_revenue > 1000
),
CountryStats AS (
    SELECT 
        n.n_name AS country,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(c.c_acctbal) AS average_balance
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    COALESCE(cs.country, 'Unknown') AS Country,
    hs.c_name AS Customer,
    hs.total_revenue AS Revenue,
    cs.customer_count AS Total_Customers,
    cs.average_balance AS Avg_Balance,
    CASE 
        WHEN hs.revenue_rank <= 10 THEN 'Top Tier'
        ELSE 'Regular' 
    END AS Customer_Category
FROM 
    HighlyProfitable hs
FULL OUTER JOIN 
    CountryStats cs ON hs.c_name IS NULL OR cs.customer_count IS NULL
WHERE 
    (hs.total_revenue IS NOT NULL OR cs.customer_count IS NOT NULL)
ORDER BY 
    hs.total_revenue DESC, 
    cs.customer_count DESC;
