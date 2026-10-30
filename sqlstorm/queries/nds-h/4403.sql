WITH SupplierPart AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_partkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), TopSuppliers AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        sp.ps_partkey, 
        sp.p_name, 
        sp.ps_availqty, 
        sp.ps_supplycost
    FROM 
        SupplierPart sp
    WHERE 
        sp.rn <= 3
), OrderLineItem AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
), RevenueSupplier AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name,
        SUM(oli.revenue) AS total_revenue
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        OrderLineItem oli ON ts.ps_partkey = oli.o_orderkey
    GROUP BY 
        ts.s_suppkey, 
        ts.s_name
)
SELECT 
    r.r_name, 
    ns.n_name, 
    COALESCE(rs.total_revenue, 0) AS supplier_revenue
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RevenueSupplier rs ON ns.n_nationkey = rs.s_suppkey 
WHERE 
    ns.n_comment IS NOT NULL
ORDER BY 
    supplier_revenue DESC, 
    ns.n_name ASC
LIMIT 10;