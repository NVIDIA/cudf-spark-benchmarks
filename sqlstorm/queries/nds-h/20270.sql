WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_per_type
    FROM part p
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(s.s_acctbal) AS max_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
NullLogicDemo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN COUNT(s.s_suppkey) IS NULL THEN 'No Suppliers'
            ELSE 'Has Suppliers'
        END AS supplier_status
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    sa.total_available,
    od.total_line_value,
    cs.order_count,
    nld.n_name,
    nld.supplier_status
FROM RankedParts rp
JOIN SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
JOIN OrderDetails od ON od.line_count > 5
JOIN CustomerSegment cs ON cs.order_count > 10
LEFT JOIN NullLogicDemo nld ON cs.c_custkey = nld.n_nationkey
WHERE 
    rp.rank_per_type <= 3 AND 
    (sa.total_available IS NULL OR sa.max_supply_cost < 100.00) AND 
    (od.total_line_value > 500 OR cs.c_mktsegment like '%Retail%')
ORDER BY rp.p_retailprice DESC
LIMIT 100;