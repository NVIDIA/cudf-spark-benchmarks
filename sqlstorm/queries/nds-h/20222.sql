
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        JOIN supplier s ON l.l_suppkey = s.s_suppkey
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= '1994-01-01' AND o.o_orderdate < '1995-01-01'
    GROUP BY 
        r.r_name
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS lineitem_count,
        AVG(l.l_extendedprice) AS avg_price,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
        LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey IS NOT NULL)
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    r.region,
    COALESCE(hv.total_spent, 0) AS high_value_spending,
    os.lineitem_count,
    os.avg_price,
    os.last_ship_date,
    CASE 
        WHEN os.lineitem_count IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales Data'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM 
    RegionalSales r
    FULL OUTER JOIN HighValueCustomers hv ON r.region IS NULL OR hv.c_custkey IS NULL
    LEFT JOIN OrderSummary os ON hv.c_custkey = os.o_orderkey
WHERE 
    r.total_sales IS NOT NULL OR hv.total_spent IS NOT NULL
ORDER BY 
    r.region, high_value_spending DESC, os.last_ship_date DESC;
