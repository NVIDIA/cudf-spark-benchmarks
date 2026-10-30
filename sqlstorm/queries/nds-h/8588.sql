WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(orders.o_totalprice) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders ON c.c_custkey = orders.o_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
Combined AS (
    SELECT 
        tr.r_name AS region_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost,
        tr.total_revenue
    FROM 
        TopRegions tr
    JOIN 
        RankedSuppliers rs ON tr.r_regionkey = rs.s_suppkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    region_name,
    supplier_name,
    total_supply_cost,
    total_revenue,
    (total_revenue - total_supply_cost) AS profit_margin
FROM 
    Combined
ORDER BY 
    profit_margin DESC
LIMIT 10;
