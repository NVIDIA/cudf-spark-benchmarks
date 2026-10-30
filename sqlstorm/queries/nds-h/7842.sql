WITH Revenue AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        l.l_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region,
        Revenue.total_revenue
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        Revenue ON s.s_suppkey = Revenue.l_suppkey
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY 
    ps.ps_partkey, p.p_name, p.p_brand, p.p_type
ORDER BY 
    total_available DESC, average_supply_cost;