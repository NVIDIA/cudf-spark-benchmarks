
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_available_quantity
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerTotal AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_brand,
    n.n_name AS supplier_nation,
    s.s_name AS supplier_name,
    COALESCE(r.total_orders, 0) AS total_orders,
    COALESCE(r.total_spent, 0) AS total_spent,
    ss.avg_available_quantity,
    ss.total_supply_cost,
    'More than $1000 spent' AS status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerTotal r ON s.s_nationkey = r.c_custkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
WHERE 
    p.p_retailprice > 500 
    AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 200)
ORDER BY 
    p.p_retailprice DESC
LIMIT 100;
