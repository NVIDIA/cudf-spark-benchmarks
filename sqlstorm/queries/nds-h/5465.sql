WITH RegionStats AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.region, 
    r.nation_count, 
    r.total_supplier_balance, 
    c.c_name, 
    c.order_count, 
    c.total_spent, 
    p.p_name, 
    p.total_available_qty, 
    p.average_supply_cost
FROM 
    RegionStats r
JOIN 
    CustomerOrders c ON r.nation_count > 5
JOIN 
    PartSupplierStats p ON p.total_available_qty > 1000
WHERE 
    r.total_supplier_balance > 10000
ORDER BY 
    r.region, c.total_spent DESC, p.average_supply_cost ASC;
