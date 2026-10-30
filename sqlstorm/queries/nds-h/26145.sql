WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_regionkey, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.s_name AS supplier_name,
    rs.region_name,
    rs.part_count,
    rs.total_supply_cost,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    RankedSuppliers rs
JOIN 
    CustomerOrders co ON co.order_count > 5
WHERE 
    rs.rank <= 5
ORDER BY 
    rs.part_count DESC, co.total_spent DESC;
