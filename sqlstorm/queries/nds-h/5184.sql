WITH SuppliersInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        SUM(ps.ps_availqty) AS total_available_qty,
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
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.nation,
        s.region,
        s.total_available_qty,
        s.total_supply_cost,
        RANK() OVER (PARTITION BY s.region ORDER BY s.total_supply_cost DESC) AS rank
    FROM 
        SuppliersInfo s
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.nation,
    t.region,
    t.total_available_qty,
    t.total_supply_cost
FROM 
    TopSuppliers t
WHERE 
    t.rank <= 5
ORDER BY 
    t.region, t.total_supply_cost DESC;
