
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        n.n_nationkey,
        AVG(ss.total_cost) AS avg_cost
    FROM 
        nation n
    JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_suppkey
    WHERE 
        ss.rn <= 5
    GROUP BY 
        n.n_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_spent,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_mktsegment
)
SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    SUM(od.net_spent) AS total_revenue,
    SUM(od.o_totalprice) AS total_ordered_value,
    (SELECT AVG(avg_cost) FROM HighCostSuppliers) AS average_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    OrderDetails od ON s.s_suppkey = od.o_orderkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(od.net_spent) > (SELECT AVG(avg_cost) FROM HighCostSuppliers)
ORDER BY 
    total_revenue DESC;
