WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
FinalReport AS (
    SELECT 
        rn.r_name AS region_name,
        ns.n_name AS nation_name,
        fs.c_name AS customer_name,
        fs.total_spent,
        rs.s_name AS supplier_name,
        rs.total_supply_cost,
        rs.rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region rn ON ns.n_regionkey = rn.r_regionkey
    JOIN 
        FilteredCustomers fs ON ns.n_nationkey = fs.c_nationkey
)
SELECT 
    region_name,
    nation_name,
    customer_name,
    total_spent,
    supplier_name,
    total_supply_cost,
    rank
FROM 
    FinalReport
WHERE 
    rank <= 3
ORDER BY 
    region_name, total_spent DESC;
