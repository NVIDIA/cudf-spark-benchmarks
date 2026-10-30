
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND o.o_totalprice IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100 AND AVG(ps.ps_supplycost) < 50
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(si.total_avail_qty, 0) AS total_availability,
    COALESCE(si.avg_supply_cost, 0) AS avg_supply_cost,
    rn.o_orderdate,
    rn.o_totalprice,
    CASE 
        WHEN rn.o_orderdate < DATE '1998-10-01' - INTERVAL '30 days' THEN 'Old'
        ELSE 'Recent'
    END AS order_age_category,
    tn.n_name AS nation_name
FROM 
    part p
LEFT JOIN 
    SupplierInfo si ON si.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedOrders rn ON rn.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal > 1000 AND c.c_mktsegment <> 'AUTOMOBILE'
    )
LEFT JOIN 
    TopNations tn ON tn.n_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'A%' 
        LIMIT 1
    )
WHERE 
    p.p_size BETWEEN (SELECT MIN(p2.p_size) FROM part p2 WHERE p2.p_retailprice > 50) 
    AND (SELECT MAX(p3.p_size) FROM part p3 WHERE p3.p_retailprice < 150)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, si.total_avail_qty, si.avg_supply_cost, rn.o_orderdate, rn.o_totalprice, tn.n_name
ORDER BY 
    p.p_partkey, rn.o_orderdate DESC
LIMIT 100;
