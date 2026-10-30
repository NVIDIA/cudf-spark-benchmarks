WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    spd.s_suppkey, 
    spd.s_name, 
    spd.total_supply_cost, 
    spd.part_count, 
    spd.region_name,
    cod.c_custkey,
    cod.c_name,
    cod.total_order_value,
    cod.order_count
FROM 
    SupplierPartDetails spd
JOIN 
    CustomerOrderDetails cod ON spd.part_count >= 5
ORDER BY 
    spd.total_supply_cost DESC, 
    cod.total_order_value DESC 
LIMIT 100;
