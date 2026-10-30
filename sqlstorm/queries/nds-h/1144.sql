WITH SupplierCost AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_supplycost) AS total_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, 
        ps_suppkey
),
HighValueOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        SUM(l_extendedprice * (1 - l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o_orderkey, o_custkey
    HAVING 
        SUM(l_extendedprice * (1 - l_discount)) > 10000
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
    COUNT(DISTINCT h.o_orderkey) AS total_high_value_orders,
    SUM(sc.total_supply_cost) AS total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
LEFT JOIN 
    HighValueOrders h ON s.s_suppkey = h.o_custkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_high_value_orders DESC, total_supplier_balance DESC
LIMIT 10;
