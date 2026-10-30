
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
), 
PartSelected AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name
)
SELECT 
    co.c_name,
    co.o_orderkey,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS revenue,
    ps.p_name,
    ps.available_quantity,
    ss.s_name AS supplier_name,
    ss.s_acctbal
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
LEFT JOIN 
    PartSelected ps ON li.l_partkey = ps.p_partkey
LEFT JOIN 
    RankedSuppliers ss ON ps.p_partkey = ss.s_suppkey AND ss.rnk = 1
WHERE 
    co.o_orderstatus IN ('O', 'F') 
    AND (ps.available_quantity IS NULL OR ps.available_quantity > 10)
GROUP BY 
    co.c_name, 
    co.o_orderkey, 
    ps.p_name,
    ps.available_quantity,
    ss.s_name,
    ss.s_acctbal
HAVING 
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) > 1000
ORDER BY 
    revenue DESC, 
    co.c_name;
