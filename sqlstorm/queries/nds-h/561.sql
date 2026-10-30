WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
NationalDiversity AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
YearlyOrderStats AS (
    SELECT 
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        EXTRACT(YEAR FROM o.o_orderdate)
)
SELECT 
    r.r_name AS region_name,
    COALESCE(nd.supplier_count, 0) AS total_suppliers,
    COALESCE(sr.total_revenue, 0) AS total_revenue,
    os.order_year,
    os.total_orders,
    os.avg_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationalDiversity nd ON n.n_nationkey = nd.n_nationkey
LEFT JOIN 
    SupplierRevenue sr ON nd.supplier_count > 0
LEFT JOIN 
    YearlyOrderStats os ON os.order_year = EXTRACT(YEAR FROM cast('1998-10-01' as date))
WHERE 
    r.r_name LIKE '%East%'
    OR (nd.supplier_count IS NULL AND sr.total_revenue IS NULL)
ORDER BY 
    region_name, order_year DESC;