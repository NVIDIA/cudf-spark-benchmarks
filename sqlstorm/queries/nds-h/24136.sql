WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
SelectedSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_nationkey
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 3
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
        AND l.l_discount IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
), 
CrossRegionRevenue AS (
    SELECT 
        r.r_name,
        SUM(co.total_revenue) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        r.r_name
), 
SupplierRevenue AS (
    SELECT 
        ss.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        SelectedSuppliers ss
    JOIN 
        partsupp ps ON ss.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ss.s_name
)
SELECT 
    cr.r_name,
    COALESCE(cr.total_revenue, 0) AS region_revenue,
    sr.supplier_revenue,
    cr.total_revenue - COALESCE(sr.supplier_revenue, 0) AS net_revenue
FROM 
    CrossRegionRevenue cr
FULL OUTER JOIN 
    SupplierRevenue sr ON cr.r_name = sr.s_name
WHERE 
    (cr.total_revenue IS NOT NULL OR sr.supplier_revenue IS NOT NULL)
ORDER BY 
    region_revenue DESC NULLS LAST, 
    supplier_revenue DESC NULLS FIRST;