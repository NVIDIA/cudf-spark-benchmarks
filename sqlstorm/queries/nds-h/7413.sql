
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name, 
        r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey AS suppkey,
        s.s_name AS name,
        s.s_acctbal AS acctbal,
        s.nation_name,
        s.region_name,
        s.total_available_quantity,
        s.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY s.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierInfo s
)
SELECT 
    t.suppkey,
    t.name,
    t.acctbal,
    t.nation_name,
    t.region_name,
    t.total_available_quantity,
    t.total_supply_cost
FROM 
    TopSuppliers t
WHERE 
    t.supply_rank <= 10
ORDER BY 
    t.total_supply_cost DESC;
