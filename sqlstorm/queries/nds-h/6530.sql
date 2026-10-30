WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        nation_name,
        p_brand,
        s_name,
        total_cost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 5
)
SELECT 
    r.r_name AS region,
    ts.p_brand,
    COUNT(DISTINCT ts.s_name) AS supplier_count,
    SUM(ts.total_cost) AS aggregate_cost
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, ts.p_brand
ORDER BY 
    r.r_name, ts.p_brand;
