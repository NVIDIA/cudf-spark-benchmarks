
WITH PartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_nationkey,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        ps.p_name,
        COUNT(*) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        MIN(ps.ps_availqty) AS min_available_quantity
    FROM 
        PartSuppliers ps
    WHERE 
        ps.rn = 1
    GROUP BY 
        ps.p_name
),
NationDetails AS (
    SELECT 
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    ts.p_name,
    ts.supplier_count,
    ts.total_supply_cost,
    ts.min_available_quantity,
    nd.n_name,
    nd.region_name,
    nd.customer_count
FROM 
    TopSuppliers ts
JOIN 
    NationDetails nd ON ts.supplier_count > nd.customer_count
ORDER BY 
    ts.total_supply_cost DESC, ts.min_available_quantity ASC;
