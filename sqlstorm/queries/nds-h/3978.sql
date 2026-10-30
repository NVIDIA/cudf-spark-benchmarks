WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS distinct_customers
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    ss.s_name,
    ss.total_available_qty,
    ss.total_supply_value,
    rs.total_sales,
    COALESCE(rs.distinct_customers, 0) AS distinct_customers,
    CASE 
        WHEN ss.total_available_qty IS NULL THEN 'Supplier Not Available' 
        ELSE 'Supplier Available' 
    END AS supplier_status
FROM SupplierStats ss
FULL OUTER JOIN RegionSales rs ON ss.total_supply_value > 0 AND rs.total_sales > 0
WHERE 
    (ss.total_supply_value > 10000 OR rs.total_sales > 5000)
    AND (ss.avg_acct_balance IS NOT NULL AND ss.avg_acct_balance > 2000)
ORDER BY 
    rs.total_sales DESC NULLS LAST, 
    ss.total_supply_value DESC NULLS LAST;
