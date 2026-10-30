WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_custkey, 
        ro.o_orderdate, 
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders)
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    fo.total_revenue, 
    COALESCE(sr.supplier_total_revenue, 0) AS supplier_revenue,
    (CASE 
        WHEN sr.supplier_total_revenue IS NULL THEN 'No Revenue' 
        WHEN sr.supplier_total_revenue > fo.total_revenue THEN 'Supplier Dominates' 
        ELSE 'Customer Dominates' 
     END) AS dominance_status
FROM 
    customer c
LEFT JOIN 
    FilteredOrders fo ON c.c_custkey = fo.o_custkey
LEFT JOIN 
    SupplierRevenue sr ON fo.o_orderkey = sr.ps_suppkey
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    fo.total_revenue DESC NULLS LAST;
