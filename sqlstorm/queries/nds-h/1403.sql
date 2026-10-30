WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_name,
        s.s_acctbal,
        sos.total_revenue,
        sos.order_count
    FROM 
        SupplierOrderSummary sos
    JOIN 
        supplier s ON sos.s_suppkey = s.s_suppkey
    WHERE 
        sos.revenue_rank <= 3
),
RegionSummary AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT ts.s_name) AS supplier_count,
        SUM(ts.total_revenue) AS total_revenue
    FROM 
        TopSuppliers ts
    JOIN 
        nation n ON ts.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.supplier_count,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    RANK() OVER (ORDER BY COALESCE(r.total_revenue, 0) DESC) AS revenue_rank
FROM 
    RegionSummary r
LEFT JOIN 
    RegionSummary r2 ON r2.n_regionkey = r.n_regionkey
WHERE 
    r.n_regionkey IS NOT NULL
ORDER BY 
    r.total_revenue DESC, r.r_name;