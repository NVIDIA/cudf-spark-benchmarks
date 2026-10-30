WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT rs.s_suppkey) AS total_suppliers,
        SUM(rs.ps_supplycost * rs.ps_availqty) AS total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    ts.region_name,
    ts.total_suppliers,
    ts.total_cost,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31') AS total_orders,
    (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31') AS avg_order_value
FROM 
    TopSuppliers ts
ORDER BY 
    ts.total_cost DESC;