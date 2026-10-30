WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS average_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_value,
        ni.total_acctbal
    FROM SupplierStats ss 
    JOIN NationInfo ni ON ss.s_name LIKE '%' || ni.n_name || '%'
    WHERE ss.total_supply_value > 10000
)

SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_type,
    rp.p_retailprice,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    ts.total_supply_value,
    ts.total_acctbal
FROM RankedParts rp
LEFT JOIN CustomerOrderCounts cs ON rp.p_partkey = cs.c_custkey
FULL OUTER JOIN TopSuppliers ts ON rp.p_mfgr = ts.s_name
WHERE rp.price_rank <= 5 
  AND (ts.total_acctbal IS NULL OR ts.total_acctbal > 5000)
ORDER BY rp.p_retailprice DESC, ts.total_supply_value ASC;
