
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL AND 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
), 
NationalSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 1000 AND 
        (o.o_orderdate < DATE '1998-10-01' - INTERVAL '1 year' 
          OR o.o_orderstatus IN ('F', 'O'))
)
SELECT 
    nc.n_name,
    rp.p_name,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    SUM(fo.o_totalprice) AS total_order_value,
    AVG(nc.total_supply_cost) AS avg_supply_cost_per_supplier,
    CASE 
        WHEN MAX(rp.p_retailprice) IS NULL THEN 'No parts found'
        ELSE 'Parts available'
    END AS availability_status
FROM 
    NationalSuppliers nc
    LEFT JOIN RankedParts rp ON nc.s_suppkey = rp.p_partkey
    LEFT JOIN FilteredOrders fo ON fo.o_orderkey = rp.p_partkey 
    LEFT JOIN region r ON nc.n_name = r.r_name 
WHERE 
    nc.total_supply_cost IS NOT NULL
GROUP BY 
    nc.n_name, rp.p_name
HAVING 
    COUNT(DISTINCT fo.o_orderkey) > 5 OR 
    SUM(fo.o_totalprice) / NULLIF(COUNT(DISTINCT fo.o_orderkey), 0) > 5000
ORDER BY 
    availability_status DESC, 
    total_order_value DESC;
