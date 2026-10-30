WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_brand,
        p.p_container,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, p.p_brand, p.p_container
),
TopSuppliers AS (
    SELECT 
        supplier_rank,
        s_suppkey,
        s_name,
        nation_name,
        p_brand,
        p_container,
        total_supply_cost
    FROM 
        RankedSuppliers
    WHERE 
        supplier_rank <= 5
)
SELECT 
    ts.nation_name,
    ts.p_brand,
    COUNT(ts.s_suppkey) AS supplier_count,
    AVG(ts.total_supply_cost) AS avg_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.nation_name, ts.p_brand
ORDER BY 
    nation_name, avg_supply_cost DESC;
