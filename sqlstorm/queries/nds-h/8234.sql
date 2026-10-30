WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name as region_name,
        n.n_name as nation_name,
        t.s_suppkey,
        t.s_name,
        SUM(t.total_supply_cost) AS total_cost
    FROM 
        RankedSuppliers t
    JOIN 
        supplier s ON t.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.rank = 1
    GROUP BY 
        r.r_name, n.n_name, t.s_suppkey, t.s_name
)
SELECT 
    region_name,
    nation_name,
    s_suppkey,
    s_name,
    total_cost
FROM 
    TopSuppliers
ORDER BY 
    region_name, nation_name, total_cost DESC
LIMIT 10;
