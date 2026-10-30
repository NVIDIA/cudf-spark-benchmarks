
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS priority_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > 1000
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        AVG(sp.total_supply_cost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container
    HAVING 
        AVG(sp.total_supply_cost) IS NOT NULL
    ORDER BY 
        avg_supply_cost DESC
    LIMIT 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    CAST(oo.o_orderdate AS STRING) AS order_date,
    tp.p_name,
    tp.avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY oo.o_orderdate DESC) AS order_rank
FROM 
    customer c
JOIN 
    RankedOrders oo ON c.c_custkey = oo.o_orderkey
JOIN 
    lineitem l ON oo.o_orderkey = l.l_orderkey
JOIN 
    TopParts tp ON l.l_partkey = tp.p_partkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
ORDER BY 
    c.c_custkey, order_rank, tp.avg_supply_cost DESC;
