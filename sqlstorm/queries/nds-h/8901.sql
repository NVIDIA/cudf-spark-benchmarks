WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
), 
CustomerRegionStats AS (
    SELECT 
        c.c_custkey,
        r.r_regionkey,
        SUM(os.total_price) AS total_spent,
        COUNT(os.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, r.r_regionkey
) 
SELECT 
    cr.c_custkey,
    cr.r_regionkey,
    cr.total_spent,
    cr.total_orders,
    ss.s_name,
    ss.total_supply_cost,
    ss.unique_parts_supplied
FROM 
    CustomerRegionStats cr
JOIN 
    SupplierStats ss ON cr.total_spent > ss.total_supply_cost
ORDER BY 
    cr.total_spent DESC, ss.total_supply_cost ASC;
