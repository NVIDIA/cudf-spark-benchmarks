WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_cost,
        ss.part_count,
        DENSE_RANK() OVER (ORDER BY ss.total_cost DESC) AS cost_rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ts.s_name,
    ts.total_cost,
    ts.part_count,
    COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
WHERE 
    ts.cost_rank <= 10 OR ts.s_name IS NULL
GROUP BY 
    r.r_name, n.n_name, ts.s_name, ts.total_cost, ts.part_count
ORDER BY 
    r.r_name, n.n_name, ts.total_cost DESC;
