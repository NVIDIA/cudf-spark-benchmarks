WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supplycost,
        ss.part_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_supplycost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierStats)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.net_revenue,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    r.r_name AS region_name
FROM 
    OrderDetails o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    supplier sup ON l.l_suppkey = sup.s_suppkey
LEFT JOIN 
    nation n ON sup.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.net_revenue IS NOT NULL
ORDER BY 
    o.net_revenue DESC
LIMIT 10;