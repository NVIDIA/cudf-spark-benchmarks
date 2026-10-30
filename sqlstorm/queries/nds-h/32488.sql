WITH  CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueOrders AS (
    SELECT 
        co.o_orderkey,
        co.c_custkey,
        co.o_totalprice,
        co.o_orderdate,
        co.c_name
    FROM 
        CustomerOrders co
    WHERE 
        co.order_rank = 1 AND co.o_totalprice > (
            SELECT 
                AVG(o.o_totalprice)
            FROM 
                orders o
        )
)

SELECT 
    DISTINCT r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
    SUM(sp.total_available) AS total_available_parts,
    SUM(sp.avg_supply_cost) AS total_avg_supply_cost
FROM 
    HighValueOrders hvo
JOIN 
    customer c ON hvo.c_custkey = c.c_custkey
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierParts sp ON hvo.o_orderkey = sp.ps_partkey
GROUP BY 
    r.r_name,
    n.n_name,
    s.s_name
HAVING 
    SUM(sp.total_available) IS NOT NULL AND 
    COUNT(DISTINCT hvo.o_orderkey) > 5
ORDER BY 
    region_name, nation_name;
